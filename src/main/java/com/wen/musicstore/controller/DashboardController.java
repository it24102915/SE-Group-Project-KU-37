package com.wen.musicstore.controller;

import com.wen.musicstore.entity.Customer;
import com.wen.musicstore.entity.Order;
import com.wen.musicstore.repository.CustomerRepository;
import com.wen.musicstore.repository.OrderRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
public class DashboardController {

    private final CustomerRepository customerRepository;
    private final OrderRepository orderRepository;

    public DashboardController(CustomerRepository customerRepository, OrderRepository orderRepository) {
        this.customerRepository = customerRepository;
        this.orderRepository = orderRepository;
    }

    private Customer getCurrentCustomer() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        if (email == null || "anonymousUser".equals(email)) {
            throw new IllegalStateException("User not authenticated. Please log in.");
        }
        return customerRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalStateException("Customer not found for email: " + email));
    }

    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        Customer customer = getCurrentCustomer();
        model.addAttribute("customer", customer);
        return "dashboard";
    }

    @GetMapping("/orders")
    public String orders(Model model) {
        try {
            Customer customer = getCurrentCustomer();
            List<Order> orders = orderRepository.findByCustomer(customer);
            // Create a list of order details with precomputed total prices
            List<Map<String, Object>> orderDetails = orders.stream().map(order -> {
                double totalPrice = order.getOrderItems().stream()
                        .mapToDouble(orderItem -> orderItem.getItem().getPrice() * orderItem.getQuantity())
                        .sum();
                return Map.of(
                        "id", order.getId(),
                        "orderItems", order.getOrderItems(),
                        "status", order.getStatus(),
                        "totalPrice", totalPrice
                );
            }).collect(Collectors.toList());
            model.addAttribute("orderDetails", orderDetails);
            return "orders";
        } catch (IllegalStateException e) {
            return "redirect:/error?message=" + java.net.URLEncoder.encode(e.getMessage(), java.nio.charset.StandardCharsets.UTF_8);
        }
    }
}