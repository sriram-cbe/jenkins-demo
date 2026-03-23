pipeline {
    agent any
    
    tools {
        // Define the JDK tool - make sure this matches your Jenkins Global Tool Configuration
        jdk 'JDK17'  // Change this to match your Jenkins JDK configuration name
    }
    
    environment {
        // Ensure JAVA_HOME is set
        JAVA_HOME = "${tool 'JDK17'}"
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
        
        // Gradle configuration
        GRADLE_OPTS = '-Dorg.gradle.daemon=false'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Environment Info') {
            steps {
                echo 'Displaying environment information...'
                sh '''
                    echo "JAVA_HOME: $JAVA_HOME"
                    echo "PATH: $PATH"
                    java -version
                    ./gradlew --version
                '''
            }
        }
        
        stage('Make Gradlew Executable') {
            steps {
                echo 'Making gradlew executable...'
                sh 'chmod +x gradlew'
            }
        }
        
        stage('Clean') {
            steps {
                echo 'Cleaning previous builds...'
                sh './gradlew clean'
            }
        }
        
        stage('Compile') {
            steps {
                echo 'Compiling the application...'
                sh './gradlew compileJava'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh './gradlew test'
            }
            post {
                always {
                    // Publish test results
                    publishTestResults testResultsPattern: 'build/test-results/test/*.xml'
                    
                    // Archive test reports
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'build/reports/tests/test',
                        reportFiles: 'index.html',
                        reportName: 'Test Report'
                    ])
                }
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building the application...'
                sh './gradlew build -x test'  // Skip tests since we ran them separately
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                echo 'Archiving build artifacts...'
                archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
            }
        }
        
        stage('Docker Build') {
            when {
                // Only build Docker image on main branch or when explicitly requested
                anyOf {
                    branch 'master'
                    branch 'main'
                    environment name: 'BUILD_DOCKER', value: 'true'
                }
            }
            steps {
                script {
                    echo 'Building Docker image...'
                    def image = docker.build("jenkins-demo:${env.BUILD_NUMBER}")
                    
                    // Tag as latest if on main branch
                    if (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main') {
                        image.tag('latest')
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
            
            // Clean workspace
            cleanWs()
        }
        
        success {
            echo 'Pipeline succeeded! ✅'
            
            // Send success notification (uncomment if you have email/Slack configured)
            // emailext (
            //     subject: "✅ Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //     body: "The build completed successfully.\n\nBuild URL: ${env.BUILD_URL}",
            //     to: "${env.CHANGE_AUTHOR_EMAIL}"
            // )
        }
        
        failure {
            echo 'Pipeline failed! ❌'
            
            // Send failure notification (uncomment if you have email/Slack configured)
            // emailext (
            //     subject: "❌ Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //     body: "The build failed. Please check the console output.\n\nBuild URL: ${env.BUILD_URL}",
            //     to: "${env.CHANGE_AUTHOR_EMAIL}"
            // )
        }
        
        unstable {
            echo 'Pipeline is unstable! ⚠️'
        }
    }
}