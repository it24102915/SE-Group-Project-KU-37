package com.wen.musicstore.repository;

import com.wen.musicstore.entity.Customer;
import com.wen.musicstore.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByCustomer(Customer customer);
}