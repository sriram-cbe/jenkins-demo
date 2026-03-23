package com.example.jenkins_demo.controllers;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@WebAppConfiguration
class HomeControllerIntegrationTest {

    @Autowired
    private WebApplicationContext webApplicationContext;

    private MockMvc mockMvc;

    @Test
    void health_ShouldReturnHealthMessage_WhenCalledViaIntegrationTest() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();

        // When & Then
        mockMvc.perform(get("/home/health"))
                .andExpect(status().isOk())
                .andExpect(content().string("The service is up and running..!!"));
    }

    @Test
    void health_ShouldReturnOkStatus_WhenCalledViaIntegrationTest() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();

        // When & Then
        mockMvc.perform(get("/home/health"))
                .andExpect(status().isOk());
    }

    @Test
    void health_ShouldReturn404_WhenCalledWithInvalidPath() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();

        // When & Then
        mockMvc.perform(get("/home/health/invalid"))
                .andExpect(status().isNotFound());
    }
}
