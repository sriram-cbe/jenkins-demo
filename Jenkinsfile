pipeline {
    agent any
    tools {
        gradle 'gradle 9.4.1'
    }
    environment {
        DOCKER_IMAGE='jenkins-demo-app'
        IMAGE_NAME='jenkins-demo'
        MAJOR_VERSION = '1'
    }
    parameters {
        choice(name : 'ENVIRONMENT', choices : ['dev','test'], description : 'Environments')
    }
    stages {
        stage('Generate Version') {
            steps {
                script {
                    // Create or read version file
                    def versionFile = 'version.txt'
                    def patchVersion = 0

                    if (fileExists(versionFile)) {
                        patchVersion = readFile(versionFile).trim() as Integer
                    }

                    // Increment patch version
                    patchVersion++

                    // Write back to file
                    writeFile file: versionFile, text: patchVersion.toString()

                    env.VERSION = "${MAJOR_VERSION}.$BUILD_NUMBER"
                    echo "Generated version: ${env.VERSION}"
                }
            }
        }
        stage('git clone') {
            steps {
                git credentialsId: '46e7fd33-a896-4870-8d49-ff3dc22b8f65', url: 'https://github.com/sriram-cbe/jenkins-demo.git'            }
        }
        stage('Show path source') {
            steps {
                sh 'echo $PATH'
            }
        }

        stage('gradle test') {
            when {
                expression {
                    params.ENVIRONMENT == 'dev'
                }
            }
            steps {
                sh '''
                # Ensure Docker is in PATH
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker not found. Please install Docker or add it to PATH"
    exit 1
fi

echo "✅ Docker found"
echo "$VERSION"
# Build the Docker image
echo "Building Docker image with version $VERSION"
docker build -t $IMAGE_NAME:$VERSION -t $IMAGE_NAME:$VERSION .
# Stop and remove any existing container
echo "Stopping existing container..."
docker stop $DOCKER_IMAGE 2>/dev/null || true
docker rm $DOCKER_IMAGE 2>/dev/null || true

# Run the new container
echo "Starting new container..."
docker run -d --name $DOCKER_IMAGE -p 8091:8090 $IMAGE_NAME:$VERSION

# Wait a moment for container to start
sleep 5

# Verify the container is running
echo "Verifying container status..."
if docker ps | grep $DOCKER_IMAGE; then
    echo "✅ Container is running successfully"

    # Optional: Test the health endpoint
    echo "Testing health endpoint..."
    sleep 5
    if curl -f http://localhost:8091/home/health 2>/dev/null; then
        echo "✅ Application health check passed"
    else
        echo "⚠️  Health check failed, but container is running"
    fi
else
    echo "❌ Container failed to start"
    echo "Container logs:"
    docker logs $DOCKER_IMAGE 2>/dev/null || echo "No logs available"
    exit 1
fi

echo "🎉 Docker deployment completed successfully!"
'''
            }
        }
        stage('build') {
            when {
                expression {
                    params.ENVIRONMENT == 'dev'
                }
            }
            steps {
                sh '''
                export JAVA_HOME=/Users/sb306x/.sdkman/candidates/java/current
                ./jenkins-build-simple.sh
                '''
            }
        }
        stage('Archive Version') {
            steps {
                // Archive the version file for next build
                archiveArtifacts artifacts: 'version.txt', allowEmptyArchive: true
            }
        }
        post {
            success {
                emailext {
                    to: 'sriram.b@equalexperts.com',
                    subject: 'Build success : ${JOB_NAME}',
                    body : 'Build completed successfully. Build number: ${BUILD_NUMBER} Version number: ${VERSION}'
                }
            }
             failure {
                            emailext {
                                to: 'sriram.b@equalexperts.com',
                                subject: 'Build success : ${JOB_NAME}',
                                body : 'Build completed successfully. Build number: ${BUILD_NUMBER} Version number: ${VERSION}'
                }
             }
        }
    }

}