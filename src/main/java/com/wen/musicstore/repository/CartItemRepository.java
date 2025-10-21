package com.wen.musicstore.repository;

import com.wen.musicstore.entity.CartItem;
import com.wen.musicstore.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CartItemRepository extends JpaRepository<CartItem, Long> {
    List<CartItem> findByCustomer(Customer customer);
}