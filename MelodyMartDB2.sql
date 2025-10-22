create database MelodyMartDB2

use MelodyMartDB2
-- 1) Users
CREATE TABLE Users (
  UserID INT IDENTITY(1,1) PRIMARY KEY,
  Username NVARCHAR(50) NOT NULL UNIQUE,
  PasswordHash NVARCHAR(255) NOT NULL,
  Email NVARCHAR(100) NOT NULL UNIQUE,
  FirstName NVARCHAR(50) NOT NULL,
  LastName NVARCHAR(50) NOT NULL,
  Phone NVARCHAR(20) NULL,
  Role NVARCHAR(30) NOT NULL DEFAULT 'customer',
    CONSTRAINT chk_users_role CHECK (Role IN ('customer','admin','order_manager','delivery_staff','payment_manager','supplier')),
  Status NVARCHAR(20) NOT NULL DEFAULT 'pending',
    CONSTRAINT chk_users_status CHECK (Status IN ('pending','active','suspended','rejected')),
  LastLogin DATETIME NULL,
  DateOfBirth DATE NULL,
  ApprovedBy INT NULL,
  ApprovedAt DATETIME NULL,
  FailedLoginAttempts INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_users_approvedby FOREIGN KEY (ApprovedBy) REFERENCES Users(UserID)
);
CREATE INDEX idx_users_email ON Users(Email);
CREATE INDEX idx_users_status ON Users(Status);


-- 2) Categories
CREATE TABLE Categories (
  CategoryID INT IDENTITY(1,1) PRIMARY KEY,
  CategoryName NVARCHAR(100) NOT NULL,
  Description NVARCHAR(MAX) NULL,
  IsActive BIT NOT NULL DEFAULT 1,
  CreatedBy INT NOT NULL,
  CONSTRAINT fk_categories_createdby FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);


-- 3) Brands
CREATE TABLE Brands (
  BrandID INT IDENTITY(1,1) PRIMARY KEY,
  BrandName NVARCHAR(100) NOT NULL UNIQUE,
  Description NVARCHAR(MAX) NULL,
  Website NVARCHAR(255) NULL,
  IsActive BIT NOT NULL DEFAULT 1
);


-- 4) Products
CREATE TABLE Products (
  ProductID INT IDENTITY(1,1) PRIMARY KEY,
  ProductName NVARCHAR(255) NOT NULL,
  Description NVARCHAR(MAX) NULL,
  Price DECIMAL(10,2) NOT NULL,
  StockQuantity INT NOT NULL DEFAULT 0,
  BrandID INT NULL,
  Weight DECIMAL(8,2) NULL,
  Status NVARCHAR(20) NOT NULL DEFAULT 'draft',
    CONSTRAINT chk_products_status CHECK (Status IN ('draft','pending','approved','rejected','discontinued')),
  CreatedBy INT NOT NULL,
  ApprovedBy INT NULL,
  Rating DECIMAL(3,2) NULL DEFAULT 0,
  CONSTRAINT fk_products_brand FOREIGN KEY (BrandID) REFERENCES Brands(BrandID),
  CONSTRAINT fk_products_createdby FOREIGN KEY (CreatedBy) REFERENCES Users(UserID),
  CONSTRAINT fk_products_approvedby FOREIGN KEY (ApprovedBy) REFERENCES Users(UserID)
);
CREATE INDEX idx_products_status ON Products(Status);
CREATE INDEX idx_products_brand ON Products(BrandID);


-- 5) Carts
CREATE TABLE Carts (
  CartID INT IDENTITY(1,1) PRIMARY KEY,
  UserID INT NOT NULL UNIQUE,
  UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
  CONSTRAINT fk_carts_user FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);


-- 6) CartItems
CREATE TABLE CartItems (
  CartItemID INT IDENTITY(1,1) PRIMARY KEY,
  CartID INT NOT NULL,
  ProductID INT NOT NULL,
  Quantity INT NOT NULL DEFAULT 1,
  UnitPrice DECIMAL(10,2) NOT NULL,
  AddedAt DATETIME NOT NULL DEFAULT GETDATE(),
  CONSTRAINT fk_cartitems_cart FOREIGN KEY (CartID) REFERENCES Carts(CartID) ON DELETE CASCADE,
  CONSTRAINT fk_cartitems_product FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
  CONSTRAINT uq_cart_product UNIQUE (CartID, ProductID)
);
CREATE INDEX idx_cartitems_cart ON CartItems(CartID);


-- 7) Orders
CREATE TABLE Orders (
  OrderID INT IDENTITY(1,1) PRIMARY KEY,
  OrderNumber NVARCHAR(50) NOT NULL UNIQUE,
  UserID INT NOT NULL,
  OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
  TotalAmount DECIMAL(10,2) NOT NULL,
  TaxAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
  ShippingAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
  DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
  FinalAmount DECIMAL(10,2) NOT NULL,
  Status NVARCHAR(20) NOT NULL DEFAULT 'pending',
    CONSTRAINT chk_orders_status CHECK (Status IN ('pending','confirmed','processing','shipped','delivered','cancelled','refunded')),
  OrderNotes NVARCHAR(MAX) NULL,
  CustomerNotes NVARCHAR(MAX) NULL,
  ConfirmedBy INT NULL,
  ConfirmedAt DATETIME NULL,
  CancelledBy INT NULL,
  CancelledAt DATETIME NULL,
  CancellationReason NVARCHAR(MAX) NULL,
  CONSTRAINT fk_orders_user FOREIGN KEY (UserID) REFERENCES Users(UserID),
  CONSTRAINT fk_orders_confirmedby FOREIGN KEY (ConfirmedBy) REFERENCES Users(UserID),
  CONSTRAINT fk_orders_cancelledby FOREIGN KEY (CancelledBy) REFERENCES Users(UserID)
);
CREATE INDEX idx_orders_user ON Orders(UserID);
CREATE INDEX idx_orders_status ON Orders(Status);
CREATE INDEX idx_orders_number ON Orders(OrderNumber);


-- 8) OrderItems
CREATE TABLE OrderItems (
  OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
  OrderID INT NOT NULL,
  ProductID INT NOT NULL,
  Quantity INT NOT NULL,
  UnitPrice DECIMAL(10,2) NOT NULL,
  Subtotal DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_orderitems_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
  CONSTRAINT fk_orderitems_product FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
CREATE INDEX idx_orderitems_order ON OrderItems(OrderID);


-- 9) PaymentMethods
CREATE TABLE PaymentMethods (
  PaymentMethodID INT IDENTITY(1,1) PRIMARY KEY,
  CustomerID INT NULL,
  Type NVARCHAR(50) NOT NULL,
  MaskedDetails NVARCHAR(200) NULL,
  ExpiryMonth INT NULL,
  ExpiryYear INT NULL,
  CONSTRAINT fk_paymentmethods_customer FOREIGN KEY (CustomerID) REFERENCES Users(UserID)
);


-- 10) Payments
CREATE TABLE Payments (
  PaymentID INT IDENTITY(1,1) PRIMARY KEY,
  OrderID INT NULL,
  PaymentMethod NVARCHAR(30) NOT NULL,
    CONSTRAINT chk_payments_method CHECK (PaymentMethod IN ('credit_card','debit_card','paypal','bank_transfer','cash_on_delivery')),
  Amount DECIMAL(10,2) NOT NULL,
  TransactionID NVARCHAR(255) NULL UNIQUE,
  PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
  Status NVARCHAR(20) NOT NULL DEFAULT 'pending',
    CONSTRAINT chk_payments_status CHECK (Status IN ('pending','processing','completed','failed','refunded','cancelled')),
  PaymentDetails NVARCHAR(MAX) NULL,
  GatewayResponse NVARCHAR(MAX) NULL,
  VerifiedBy INT NULL,
  VerifiedAt DATETIME NULL,
  RefundedBy INT NULL,
  RefundedAt DATETIME NULL,
  RefundReason NVARCHAR(MAX) NULL,
  CONSTRAINT fk_payments_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
  CONSTRAINT fk_payments_verifiedby FOREIGN KEY (VerifiedBy) REFERENCES Users(UserID),
  CONSTRAINT fk_payments_refundedby FOREIGN KEY (RefundedBy) REFERENCES Users(UserID)
);
CREATE INDEX idx_payments_status ON Payments(Status);
CREATE INDEX idx_payments_order ON Payments(OrderID);


-- 11) Addresses
CREATE TABLE Addresses (
  AddressID INT IDENTITY(1,1) PRIMARY KEY,
  UserID INT NOT NULL,
  AddressType NVARCHAR(20) NOT NULL DEFAULT 'shipping',
    CONSTRAINT chk_addresses_type CHECK (AddressType IN ('billing','shipping')),
  FullName NVARCHAR(100) NOT NULL,
  Phone NVARCHAR(20) NULL,
  StreetAddress NVARCHAR(255) NOT NULL,
  City NVARCHAR(100) NOT NULL,
  State NVARCHAR(100) NOT NULL,
  PostalCode NVARCHAR(20) NOT NULL,
  Country NVARCHAR(100) NOT NULL,
  IsDefault BIT NOT NULL DEFAULT 0,
  CONSTRAINT fk_addresses_user FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);


-- 12) Deliveries (SQL Server version)
CREATE TABLE Deliveries (
  DeliveryID BIGINT IDENTITY(1,1) PRIMARY KEY,
  -- JPA field orderId is a String: we store it as OrderNumber
  OrderNumber NVARCHAR(100) NULL,    -- maps to Delivery.orderId (String) used by JPA
  OrderID INT NULL,                  -- optional FK to Orders.OrderID
  AddressID INT NULL,                -- optional FK to Addresses.AddressID

  Item NVARCHAR(255) NOT NULL,       -- JPA Delivery.item
  Name NVARCHAR(200) NOT NULL,       -- JPA Delivery.name
  Phone NVARCHAR(50) NOT NULL,       -- JPA Delivery.phone
  Address NVARCHAR(500) NOT NULL,    -- JPA Delivery.address

  -- tracking/assignment
  AssignedTo INT NULL,               -- FK -> Users(UserID) (delivery staff)
  ShippingMethod NVARCHAR(100) NULL,
  ShippingCost DECIMAL(10,2) NULL DEFAULT 0,
  TrackingNumber NVARCHAR(255) NULL UNIQUE,
  EstimatedDelivery DATE NULL,
  ActualDelivery DATETIME NULL,

  -- boolean status used by JPA entity (exact column name = status)
  status BIT NOT NULL DEFAULT 0,     -- maps to Java Delivery.status (boolean)

  -- optional textual lifecycle status
  status_text NVARCHAR(20) NULL,
    -- if used, ensure it stores lifecycle words like assigned/shipped/delivered/failed
  DeliveryNotes NVARCHAR(MAX) NULL,
  CustomerSignature BIT NOT NULL DEFAULT 0,

  created_at DATETIME NOT NULL DEFAULT GETDATE(),
  updated_at DATETIME NOT NULL DEFAULT GETDATE(),

  CONSTRAINT fk_deliveries_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
  CONSTRAINT fk_deliveries_address FOREIGN KEY (AddressID) REFERENCES Addresses(AddressID),
  CONSTRAINT fk_deliveries_assignedto FOREIGN KEY (AssignedTo) REFERENCES Users(UserID)
);
-- Trigger to update updated_at on UPDATE (to mirror JPA @PreUpdate)
IF OBJECT_ID('TRG_Deliveries_UpdateUpdatedAt','TR') IS NOT NULL
  DROP TRIGGER TRG_Deliveries_UpdateUpdatedAt;
GO
CREATE TRIGGER TRG_Deliveries_UpdateUpdatedAt
ON Deliveries
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE Deliveries
  SET updated_at = GETDATE()
  FROM Deliveries d
  JOIN inserted i ON d.DeliveryID = i.DeliveryID;
END;
GO
CREATE INDEX idx_deliveries_status ON Deliveries(status);
CREATE INDEX idx_deliveries_assigned ON Deliveries(AssignedTo);
CREATE INDEX idx_deliveries_ordernumber ON Deliveries(OrderNumber);
CREATE INDEX idx_deliveries_name ON Deliveries(Name);


-- 13) OrderStatusHistory
CREATE TABLE OrderStatusHistory (
  HistoryID INT IDENTITY(1,1) PRIMARY KEY,
  OrderID INT NOT NULL,
  Status NVARCHAR(20) NOT NULL,
    CONSTRAINT chk_orderhistory_status CHECK (Status IN ('pending','confirmed','processing','shipped','delivered','cancelled','refunded')),
  ChangedBy INT NULL,
  ChangedAt DATETIME NOT NULL DEFAULT GETDATE(),
  Notes NVARCHAR(MAX) NULL,
  CONSTRAINT fk_orderhistory_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
  CONSTRAINT fk_orderhistory_changedby FOREIGN KEY (ChangedBy) REFERENCES Users(UserID)
);
CREATE INDEX idx_orderhistory_order ON OrderStatusHistory(OrderID);


-- 14) InventoryLog
CREATE TABLE InventoryLog (
  LogID INT IDENTITY(1,1) PRIMARY KEY,
  ProductID INT NOT NULL,
  ChangeType NVARCHAR(20) NOT NULL,
    CONSTRAINT chk_inventorylog_changetype CHECK (ChangeType IN ('incoming','outgoing','adjustment','return')),
  QuantityChange INT NOT NULL,
  NewStockQuantity INT NOT NULL,
  Reason NVARCHAR(255) NULL,
  ReferenceID INT NULL,
  ReferenceType NVARCHAR(50) NULL,
  CreatedBy INT NULL,
  CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
  CONSTRAINT fk_inventorylog_product FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
  CONSTRAINT fk_inventorylog_createdby FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);
CREATE INDEX idx_inventorylog_product ON InventoryLog(ProductID);


-- 15) ProductReviews
CREATE TABLE ProductReviews (
  ReviewID INT IDENTITY(1,1) PRIMARY KEY,
  ProductID INT NOT NULL,
  UserID INT NOT NULL,
  OrderID INT NOT NULL,
  Rating INT NOT NULL,
    CONSTRAINT chk_productreviews_rating CHECK (Rating BETWEEN 1 AND 5),
  Title NVARCHAR(200) NULL,
  ReviewText NVARCHAR(MAX) NULL,
  Status NVARCHAR(20) NOT NULL DEFAULT 'pending',
    CONSTRAINT chk_productreviews_status CHECK (Status IN ('pending','approved','rejected')),
  ApprovedBy INT NULL,
  CONSTRAINT fk_productreviews_product FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
  CONSTRAINT fk_productreviews_user FOREIGN KEY (UserID) REFERENCES Users(UserID),
  CONSTRAINT fk_productreviews_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
  CONSTRAINT fk_productreviews_approvedby FOREIGN KEY (ApprovedBy) REFERENCES Users(UserID),
  CONSTRAINT uq_order_product_review UNIQUE (OrderID, ProductID)
);


-- 16) SystemSettings
CREATE TABLE SystemSettings (
  SettingID INT IDENTITY(1,1) PRIMARY KEY,
  SettingKey NVARCHAR(100) NOT NULL UNIQUE,
  SettingValue NVARCHAR(MAX) NOT NULL,
  Description NVARCHAR(MAX) NULL,
  UpdatedBy INT NULL,
  UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
  CONSTRAINT fk_systemsettings_updatedby FOREIGN KEY (UpdatedBy) REFERENCES Users(UserID)
);

-- 17) SupplierProduct
CREATE TABLE SupplierProduct (
  SupplierID INT NOT NULL,
  ProductID INT NOT NULL,
  SupplyPrice DECIMAL(12,2) NULL,
  LastSupplyDate DATE NULL,
  PRIMARY KEY (SupplierID, ProductID),
  CONSTRAINT fk_supplierproduct_supplier FOREIGN KEY (SupplierID) REFERENCES Users(UserID),
  CONSTRAINT fk_supplierproduct_product FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Final: some helper indexes
CREATE INDEX idx_payments_order ON Payments(OrderID);
CREATE INDEX idx_deliveries_tracking ON Deliveries(TrackingNumber);

--Part C
--Insert Users
INSERT INTO Users (Username, PasswordHash, Email, FirstName, LastName, Phone, Role, Status)
VALUES
('Amasha', 'hash1', 'Amasha@gmail.com', 'Amasha', 'Ekanayaka', '0711234567', 'customer', 'active'),
('Kavindu', 'hash2', 'Kavindu@gmail.com', 'Kavindu', 'Perera', '0779876543', 'customer', 'active'),
('Tharindu', 'hash3', 'Tharindu@gmail.com', 'Tharindu', 'Silva', '0714567890', 'customer', 'active'),
('delivery01', 'hash4', 'delivery@melodymart.lk', 'Nipun', 'Fernando', '0762233445', 'delivery_staff', 'active'),
('Isuru', 'hash5', 'Isuru@gmail.com', 'Isuru', 'Bandara', '0759988776', 'customer', 'active');

---Insert Categories
INSERT INTO Categories (CategoryName, Description, CreatedBy)
VALUES
('Guitars', 'Acoustic and Electric Guitars', 2),
('Keyboards', 'Digital and Acoustic Keyboards', 2),
('Drums', 'Percussion Instruments', 2),
('Wind Instruments', 'Flutes, Saxophones, etc.', 2),
('Accessories', 'Instrument Accessories', 2);

---Insert Brands
INSERT INTO Brands (BrandName, Description, Website)
VALUES
('Yamaha', 'Japanese musical instrument brand', 'https://www.yamaha.com'),
('Ibanez', 'Electric guitar manufacturer', 'https://www.ibanez.com'),
('Casio', 'Electronic keyboard brand', 'https://www.casio.com'),
('Roland', 'Synthesizers and drums', 'https://www.roland.com'),
('Tama', 'Drum manufacturer', 'https://www.tama.com');

---Insert Products 
INSERT INTO Products (ProductName, Description, Price, StockQuantity, BrandID, Weight, Status, CreatedBy)
VALUES
('Yamaha F310 Guitar', 'Acoustic guitar ideal for beginners', 32000.00, 10, 1, 2.5, 'approved', 2),
('Ibanez GRX70QA', 'Electric guitar for intermediate players', 58000.00, 5, 2, 3.0, 'approved', 2),
('Casio CT-X700 Keyboard', '61-key digital keyboard', 45000.00, 8, 3, 4.0, 'approved', 2),
('Roland TD-1K Drum Set', 'Electronic drum kit', 120000.00, 3, 4, 15.0, 'approved', 2),
('Tama Imperialstar Snare', 'Snare drum with steel shell', 18000.00, 12, 5, 5.0, 'approved', 2);

---Insert Carts 
INSERT INTO Carts (UserID)
VALUES
(1),
(2),
(3),
(4),
(5);

---Insert CartItems
INSERT INTO CartItems (CartID, ProductID, Quantity, UnitPrice)
VALUES
(1, 1, 1, 32000.00),
(1, 3, 1, 45000.00),
(2, 2, 2, 58000.00),
(3, 4, 1, 120000.00),
(4, 5, 1, 18000.00);

---Insert Orders
INSERT INTO Orders (OrderNumber, UserID, TotalAmount, FinalAmount, Status)
VALUES
('ORD001', 1, 77000.00, 77000.00, 'confirmed'),
('ORD002', 2, 116000.00, 116000.00, 'delivered'),
('ORD003', 3, 120000.00, 120000.00, 'pending'),
('ORD004', 4, 18000.00, 18000.00, 'shipped'),
('ORD005', 5, 58000.00, 58000.00, 'processing');

---Insert OrderItems
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice, Subtotal)
VALUES
(1, 1, 1, 32000.00, 32000.00),
(1, 3, 1, 45000.00, 45000.00),
(2, 2, 2, 58000.00, 116000.00),
(3, 4, 1, 120000.00, 120000.00),
(4, 5, 1, 18000.00, 18000.00);

---Insert PaymentMethods
INSERT INTO PaymentMethods (CustomerID, Type, MaskedDetails, ExpiryMonth, ExpiryYear)
VALUES
(1, 'credit_card', '**** **** **** 3456', 10, 2026),
(2, 'credit_card', '**** **** **** 7821', 5, 2027),
(3, 'cash_on_delivery', NULL, NULL, NULL),
(4, 'cash_on_delivery', NULL, NULL, NULL),
(5, 'credit_card', '**** **** **** 9987', 3, 2028);

---Insert Payments
INSERT INTO Payments (OrderID, PaymentMethod, Amount, Status, TransactionID)
VALUES
(1, 'credit_card', 77500.00, 'completed', 'TXN-SL-1001'),
(2, 'credit_card', 65000.00, 'completed', 'TXN-SL-1002'),
(3, 'cash_on_delivery', 24000.00, 'pending', 'TXN-SL-1003'),
(4, 'credit_card', 98250.00, 'completed', 'TXN-SL-1004'),
(5, 'cash_on_delivery', 18000.00, 'pending', 'TXN-SL-1005');

---Insert Addresses
INSERT INTO Addresses (UserID, AddressType, FullName, Phone, StreetAddress, City, State, PostalCode, Country)
VALUES
(1, 'shipping', 'Amasha Ekanayaka', '0711234567', 'No 45, Temple Road', 'Kandy', 'Central', '20000', 'Sri Lanka'),
(2, 'billing', 'Kavindu Perera', '0779876543', 'No 12, High Level Road', 'Nugegoda', 'Western', '10250', 'Sri Lanka'),
(3, 'shipping', 'Tharindu Silva', '0714567890', 'No 23, Galle Road', 'Colombo', 'Western', '00300', 'Sri Lanka'),
(4, 'shipping', 'Nipun Fernando', '0762233445', 'No 17, Hill Street', 'Dehiwala', 'Western', '10350', 'Sri Lanka'),
(5, 'shipping', 'Isuru Bandara', '0759988776', 'No 89, Main Street', 'Kurunegala', 'North Western', '60000', 'Sri Lanka');

---Insert Deliveries
INSERT INTO Deliveries (OrderNumber, OrderID, AddressID, Item, Name, Phone, Address, AssignedTo, ShippingMethod, ShippingCost, TrackingNumber, EstimatedDelivery, status, status_text)
VALUES
('ORD001', 1, 1, 'Yamaha F310 Guitar', 'Amasha Ekanayaka', '0711234567', 'No 45, Temple Road, Kandy', 4, 'Standard', 500.00, 'TRK001', '2025-10-12', 1, 'delivered'),
('ORD002', 2, 2, 'Ibanez GRX70QA', 'Kavindu Perera', '0779876543', 'No 12, High Level Road, Nugegoda', 4, 'Express', 750.00, 'TRK002', '2025-10-13', 1, 'delivered'),
('ORD003', 3, 3, 'Roland TD-1K Drum Set', 'Tharindu Silva', '0714567890', 'No 23, Galle Road, Colombo', 4, 'Standard', 600.00, 'TRK003', '2025-10-14', 0, 'pending'),
('ORD004', 4, 4, 'Tama Snare Drum', 'Nipun Fernando', '0762233445', 'No 17, Hill Street, Dehiwala', 4, 'Express', 800.00, 'TRK004', '2025-10-15', 0, 'shipped'),
('ORD005', 5, 5, 'Casio CT-X700 Keyboard', 'Isuru Bandara', '0759988776', 'No 89, Main Street, Kurunegala', 4, 'Standard', 500.00, 'TRK005', '2025-10-16', 0, 'processing');


SELECT * FROM Users;
SELECT * FROM Products;
SELECT * FROM Orders;
SELECT * FROM Deliveries;
SELECT * FROM Payments;
SELECT * FROM Carts ;
SELECT * FROM CartItems;
SELECT * FROM OrderItems;
SELECT * FROM PaymentMethods;
SELECT * FROM Addresses;
SELECT * FROM Brands;
SELECT * FROM Categories;





--Part D
SELECT ProductID, ProductName, Price, StockQuantity
FROM Products
WHERE Price > 40000;
--Explanation:
--This query retrieves all products priced above Rs. 40,000 — showing their ID, name, price, and available stock.

SELECT o.OrderNumber, u.FirstName + ' ' + u.LastName AS CustomerName, p.PaymentMethod, p.Amount
FROM Orders o
JOIN Users u ON o.UserID = u.UserID
JOIN Payments p ON o.OrderID = p.OrderID;
--Explanation:
--This query joins Orders, Users, and Payments tables to show who placed which order, how they paid, and how much they paid.

SELECT COUNT(*) AS TotalOrders, SUM(FinalAmount) AS TotalSales
FROM Orders
WHERE Status IN ('confirmed', 'delivered', 'shipped', 'processing');
--Explanation:
--Calculates the total number of completed/active orders and their combined sales value.

SELECT u.FirstName + ' ' + u.LastName AS CustomerName,
       COUNT(o.OrderID) AS OrderCount,
       SUM(o.FinalAmount) AS TotalSpent
FROM Users u
JOIN Orders o ON u.UserID = o.UserID
GROUP BY u.FirstName, u.LastName
HAVING COUNT(o.OrderID) >= 1;
--Explanation:
--Shows how many orders each customer has placed and how much they have spent in total.

SELECT ProductName, Price
FROM Products
WHERE Price > (
    SELECT AVG(Price) FROM Products
);
--Explanation:
--Displays all products that are more expensive than the average product price.


--part E

-- Drop if already exists
IF OBJECT_ID('CalculateOrderTotal', 'P') IS NOT NULL
    DROP PROCEDURE CalculateOrderTotal;
GO

CREATE PROCEDURE CalculateOrderTotal
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total DECIMAL(10,2);

    -- Calculate the sum of Subtotals for the given OrderID
    SELECT @Total = SUM(Subtotal)
    FROM OrderItems
    WHERE OrderID = @OrderID;

    -- Update the Orders table with the new totals
    UPDATE Orders
    SET TotalAmount = @Total,
        FinalAmount = @Total
    WHERE OrderID = @OrderID;

    -- Return the calculated total
    SELECT @OrderID AS OrderID, @Total AS CalculatedTotal;
END;
GO

EXEC CalculateOrderTotal @OrderID = 1;

--part F
IF OBJECT_ID('TRG_UpdateProductStock', 'TR') IS NOT NULL
    DROP TRIGGER TRG_UpdateProductStock;
GO

CREATE TRIGGER TRG_UpdateProductStock
ON OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Products
    SET StockQuantity = StockQuantity - i.Quantity
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;

    INSERT INTO InventoryLog (ProductID, ChangeType, QuantityChange, NewStockQuantity, Reason)
    SELECT 
        i.ProductID,
        'outgoing',
        -i.Quantity,
        (p.StockQuantity - i.Quantity),
        'Order placed (trigger)'
    FROM inserted i
    INNER JOIN Products p ON p.ProductID = i.ProductID;
END;
GO

SELECT ProductID, ProductName, StockQuantity
FROM Products
WHERE ProductID = 1;

INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice, Subtotal)
VALUES (1, 1, 2, 32000.00, 64000.00);


SELECT TOP 5 *
FROM InventoryLog
ORDER BY LogID DESC;

UPDATE OrderItems
SET Quantity = 3
WHERE OrderItemID = 1;

SELECT ProductID, StockQuantity FROM Products WHERE ProductID = 1;
SELECT TOP 5 * FROM InventoryLog ORDER BY LogID DESC;



