package com.wen.musicstore.controller;

import com.wen.musicstore.entity.CartItem;
import com.wen.musicstore.entity.Item;
import com.wen.musicstore.entity.Order;
import com.wen.musicstore.entity.OrderItem;
import com.wen.musicstore.repository.*;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
public class StoreController {

    private final CustomerRepository customerRepository;
    private final ItemRepository itemRepository;
    private final CartItemRepository cartItemRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;

    public StoreController(CustomerRepository customerRepository, ItemRepository itemRepository,
                           CartItemRepository cartItemRepository, OrderRepository orderRepository,
                           OrderItemRepository orderItemRepository) {
        this.customerRepository = customerRepository;
        this.itemRepository = itemRepository;
        this.cartItemRepository = cartItemRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
    }

    private com.wen.musicstore.entity.Customer getCurrentCustomer() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        if (email == null || "anonymousUser".equals(email)) {
            throw new IllegalStateException("User not authenticated. Please log in.");
        }
        return customerRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalStateException("Customer not found for email: " + email));
    }

    @GetMapping("/store")
    public String store(Model model) {
        List<Item> items = itemRepository.findAll();
        Map<String, List<Item>> groupedItems = items.stream()
                .collect(Collectors.groupingBy(Item::getCategory));
        model.addAttribute("groupedItems", groupedItems);
        return "store";
    }

    @PostMapping("/add-to-cart")
    public String addToCart(@RequestParam Long itemId, @RequestParam int quantity) {
        try {
            com.wen.musicstore.entity.Customer customer = getCurrentCustomer();
            Item item = itemRepository.findById(itemId)
                    .orElseThrow(() -> new IllegalArgumentException("Item not found: " + itemId));
            if (quantity > item.getQuantity() || quantity <= 0) {
                return "redirect:/store?error=" + URLEncoder.encode("Invalid quantity for item: " + item.getName(), StandardCharsets.UTF_8);
            }
            CartItem cartItem = new CartItem();
            cartItem.setCustomer(customer);
            cartItem.setItem(item);
            cartItem.setQuantity(quantity);
            cartItemRepository.save(cartItem);
            return "redirect:/store?success=Item+added+to+cart";
        } catch (IllegalStateException | IllegalArgumentException e) {
            return "redirect:/error?message=" + URLEncoder.encode(e.getMessage(), StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "redirect:/error?message=" + URLEncoder.encode("Failed to add item to cart: " + e.getMessage(), StandardCharsets.UTF_8);
        }
    }

    @GetMapping("/cart")
    public String cart(Model model) {
        try {
            com.wen.musicstore.entity.Customer customer = getCurrentCustomer();
            List<CartItem> cartItems = cartItemRepository.findByCustomer(customer);
            double totalPrice = cartItems.stream()
                    .mapToDouble(cartItem -> cartItem.getItem().getPrice() * cartItem.getQuantity())
                    .sum();
            model.addAttribute("cartItems", cartItems);
            model.addAttribute("totalPrice", totalPrice);
            return "cart";
        } catch (IllegalStateException e) {
            return "redirect:/error?message=" + URLEncoder.encode(e.getMessage(), StandardCharsets.UTF_8);
        }
    }

    @PostMapping("/order")
    public String placeOrder() {
        try {
            com.wen.musicstore.entity.Customer customer = getCurrentCustomer();
            List<CartItem> cartItems = cartItemRepository.findByCustomer(customer);
            if (cartItems.isEmpty()) {
                return "redirect:/cart?error=Cart+is+empty";
            }

            Order order = new Order();
            order.setCustomer(customer);
            order.setDate(new Date());
            order.setStatus("PENDING");
            orderRepository.save(order);

            for (CartItem cartItem : cartItems) {
                Item item = cartItem.getItem();
                if (item.getQuantity() < cartItem.getQuantity()) {
                    return "redirect:/cart?error=" + URLEncoder.encode("Insufficient stock for item: " + item.getName(), StandardCharsets.UTF_8);
                }
                OrderItem orderItem = new OrderItem();
                orderItem.setOrder(order);
                orderItem.setItem(item);
                orderItem.setQuantity(cartItem.getQuantity());
                orderItemRepository.save(orderItem);

                item.setQuantity(item.getQuantity() - cartItem.getQuantity());
                itemRepository.save(item);
            }

            cartItemRepository.deleteAll(cartItems);
            return "redirect:/dashboard?success=Order+placed+successfully";
        } catch (IllegalStateException e) {
            return "redirect:/error?message=" + URLEncoder.encode(e.getMessage(), StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "redirect:/error?message=" + URLEncoder.encode("Failed to place order: " + e.getMessage(), StandardCharsets.UTF_8);
        }
    }
}