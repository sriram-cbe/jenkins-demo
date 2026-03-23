package com.example.jenkins_demo.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class HomeControllerUnitTest {

    private HomeController homeController;

    @BeforeEach
    void setUp() {
        homeController = new HomeController();
    }

    @Test
    void health_ShouldReturnExpectedMessage_WhenCalled() {
        // When
        String result = homeController.health();

        // Then
        assertThat(result).isEqualTo("The service is up and running..");
    }

    @Test
    void health_ShouldReturnNonNullValue_WhenCalled() {
        // When
        String result = homeController.health();

        // Then
        assertThat(result).isNotNull();
    }

    @Test
    void health_ShouldReturnNonEmptyString_WhenCalled() {
        // When
        String result = homeController.health();

        // Then
        assertThat(result).isNotEmpty();
    }

    @Test
    void health_ShouldReturnConsistentResult_WhenCalledMultipleTimes() {
        // When
        String result1 = homeController.health();
        String result2 = homeController.health();
        String result3 = homeController.health();

        // Then
        assertThat(result1).isEqualTo(result2);
        assertThat(result2).isEqualTo(result3);
        assertThat(result1).isEqualTo("The service is up and running..");
    }
}