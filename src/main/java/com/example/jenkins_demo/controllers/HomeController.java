package com.example.jenkins_demo.controllers;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/home/health")
@AllArgsConstructor
public class HomeController {

    @GetMapping
    public String health() {
        return "The service is up and running..!!";
    }
}
