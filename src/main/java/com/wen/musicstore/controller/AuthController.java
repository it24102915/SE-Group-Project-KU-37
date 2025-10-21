package com.wen.musicstore.controller;

import com.wen.musicstore.entity.Customer;
import com.wen.musicstore.service.CustomerService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class AuthController {

    private final CustomerService customerService;

    public AuthController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping("/")
    public String authPage(Model model, @RequestParam(value = "error", required = false) String error,
                           @RequestParam(value = "registered", required = false) String registered) {
        if (error != null) {
            model.addAttribute("error", "Invalid email or password. Please try again.");
        }
        if (registered != null) {
            model.addAttribute("registered", true);
        }
        return "index";
    }

    @PostMapping("/register")
    public String register(Customer customer, Model model) {
        try {
            customerService.register(customer);
            return "redirect:/?registered=true";
        } catch (Exception e) {
            model.addAttribute("error", "Registration failed: " + e.getMessage());
            return "index";
        }
    }
}