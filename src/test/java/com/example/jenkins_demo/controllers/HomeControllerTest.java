package com.example.jenkins_demo.controllers;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@WebAppConfiguration
class HomeControllerTest {

    @Autowired
    private WebApplicationContext webApplicationContext;

    private MockMvc mockMvc;

    @Test
    void health_ShouldReturnSuccessMessage_WhenCalled() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // When & Then
        mockMvc.perform(get("/home/health"))
                .andExpect(status().isOk())
                .andExpect(content().string("The service is up and running..!!"));
    }

    @Test
    void health_ShouldReturnOkStatus_WhenCalled() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // When & Then
        mockMvc.perform(get("/home/health"))
                .andExpect(status().isOk());
    }

    @Test
    void health_ShouldHandleGetRequest_WhenCalledWithCorrectPath() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // When & Then
        mockMvc.perform(get("/home/health"))
                .andExpect(status().isOk())
                .andExpect(content().string("The service is up and running..!!"));
    }

    @Test
    void health_ShouldReturn404_WhenCalledWithIncorrectPath() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // When & Then
        mockMvc.perform(get("/home/health/invalid"))
                .andExpect(status().isNotFound());
    }

    @Test
    void health_ShouldReturn405_WhenCalledWithPostMethod() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // When & Then
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post("/home/health"))
                .andExpect(status().isMethodNotAllowed());
    }

    @Test
    void health_ShouldReturn405_WhenCalledWithPutMethod() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // When & Then
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/home/health"))
                .andExpect(status().isMethodNotAllowed());
    }

    @Test
    void health_ShouldReturn405_WhenCalledWithDeleteMethod() throws Exception {
        // Given
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // When & Then
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete("/home/health"))
                .andExpect(status().isMethodNotAllowed());
    }
}
