use proyectosql; 

-- ==============================================================================
-- INSERCIÓN DE DATOS DE PRUEBA
-- ==============================================================================

-- 1. Categorías (5 registros)
INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónica', 'Dispositivos tecnológicos, computadoras y accesorios'),
('Ropa y Accesorios', 'Prendas de vestir para hombre y mujer, zapatos'),
('Hogar y Cocina', 'Muebles, electrodomésticos y decoración'),
('Deportes', 'Equipamiento deportivo y ropa de entrenamiento'),
('Juguetes', 'Juegos de mesa, figuras de acción y juguetes didácticos');

-- 2. Proveedores (5 registros)
INSERT INTO proveedores (nombre, email_contacto, telefono_contacto) VALUES
('TechDistributor Latam', 'ventas@techdistributor.com', '+573001234567'),
('Moda Mayorista SAS', 'contacto@modamayorista.co', '+573109876543'),
('HomeGoods Inc', 'importaciones@homegoods.com', '+573155554444'),
('SportsGear Corp', 'distribucion@sportsgear.com', '+573201112233'),
('FunToys Supplier', 'pedidos@funtoys.com', '+573112223344');

-- 3. Clientes (10 registros con diferentes fechas de registro para análisis de cohortes)
INSERT INTO clientes (nombre, apellido, email, contraseña, direccion_envio, fecha_registro) VALUES
('Carlos', 'Ramírez', 'carlos.ramirez@email.com', 'hash_pwd_1', 'Calle 45 # 12-34, Bogotá', '2025-06-15 10:00:00'),
('Ana', 'Gómez', 'ana.gomez@email.com', 'hash_pwd_2', 'Cra 27 # 9-15, Bucaramanga', '2025-07-20 14:30:00'),
('Luis', 'Fernández', 'luis.fernandez@email.com', 'hash_pwd_3', 'Av Poblado # 43-2, Medellín', '2025-08-05 09:15:00'),
('Marta', 'Silva', 'marta.silva@email.com', 'hash_pwd_4', 'Calle 50 # 10-10, Cali', '2025-10-12 16:45:00'),
('Jorge', 'Pérez', 'jorge.perez@email.com', 'hash_pwd_5', 'Cra 15 # 100-20, Bogotá', '2025-11-25 11:20:00'),
('Laura', 'Rojas', 'laura.rojas@email.com', 'hash_pwd_6', 'Calle 10 # 5-50, Cartagena', '2026-01-10 08:00:00'),
('Diego', 'Martínez', 'diego.martinez@email.com', 'hash_pwd_7', 'Cra 5 # 60-12, Bucaramanga', '2026-02-14 19:30:00'),
('Sofía', 'López', 'sofia.lopez@email.com', 'hash_pwd_8', 'Av 33 # 40-10, Medellín', '2026-03-01 13:10:00'),
('Andrés', 'Castro', 'andres.castro@email.com', 'hash_pwd_9', 'Calle 80 # 70-30, Bogotá', '2026-04-15 17:00:00'),
('Valentina', 'Díaz', 'valentina.diaz@email.com', 'hash_pwd_10', 'Cra 45 # 20-15, Barranquilla', '2026-05-20 10:45:00');

-- 4. Productos (20 registros con variedad de precios y stocks)
INSERT INTO productos (id_categoria, id_proveedor, nombre, descripcion, precio, costo, stock, sku, fecha_creacion, activo) VALUES
-- Electrónica
(1, 1, 'Laptop Pro 15', 'Computadora portátil de alto rendimiento', 1200.00, 900.00, 15, 'ELEC-LAP-001', '2025-05-01 08:00:00', TRUE),
(1, 1, 'Smartphone X', 'Teléfono inteligente con cámara de 108MP', 800.00, 600.00, 30, 'ELEC-PHO-002', '2025-05-01 08:00:00', TRUE),
(1, 1, 'Auriculares Inalámbricos', 'Auriculares con cancelación de ruido', 150.00, 90.00, 50, 'ELEC-AUD-003', '2025-06-10 08:00:00', TRUE),
(1, 1, 'Monitor 4K 27"', 'Monitor ideal para diseño y gaming', 350.00, 250.00, 10, 'ELEC-MON-004', '2025-06-10 08:00:00', TRUE),
-- Ropa
(2, 2, 'Camiseta Básica Algodón', 'Camiseta unicolor cuello redondo', 20.00, 8.00, 100, 'ROPA-CAM-001', '2025-05-15 08:00:00', TRUE),
(2, 2, 'Pantalón Jean Clásico', 'Pantalón en denim ajuste recto', 45.00, 20.00, 60, 'ROPA-PAN-002', '2025-05-15 08:00:00', TRUE),
(2, 2, 'Chaqueta Impermeable', 'Chaqueta ligera para lluvia', 85.00, 40.00, 25, 'ROPA-CHA-003', '2025-07-01 08:00:00', TRUE),
(2, 2, 'Zapatillas Deportivas', 'Calzado para correr', 90.00, 45.00, 40, 'ROPA-ZAP-004', '2025-07-01 08:00:00', TRUE),
-- Hogar
(3, 3, 'Sofá 3 Puestos', 'Sofá moderno tapizado en tela', 450.00, 250.00, 5, 'HOG-SOF-001', '2025-08-10 08:00:00', TRUE),
(3, 3, 'Lámpara de Pie', 'Lámpara minimalista LED', 60.00, 25.00, 20, 'HOG-LAM-002', '2025-08-10 08:00:00', TRUE),
(3, 3, 'Sartén Antiadherente', 'Sartén de 24cm', 30.00, 12.00, 80, 'HOG-SAR-003', '2025-09-05 08:00:00', TRUE),
(3, 3, 'Licuadora Pro', 'Licuadora de 1000W con vaso de vidrio', 110.00, 55.00, 15, 'HOG-LIC-004', '2025-09-05 08:00:00', TRUE),
-- Deportes
(4, 4, 'Balón de Fútbol', 'Balón oficial talla 5', 35.00, 15.00, 50, 'DEP-BAL-001', '2025-10-20 08:00:00', TRUE),
(4, 4, 'Raqueta de Tenis', 'Raqueta profesional en fibra de carbono', 120.00, 70.00, 12, 'DEP-RAQ-002', '2025-10-20 08:00:00', TRUE),
(4, 4, 'Set de Pesas 20kg', 'Mancuernas ajustables', 85.00, 40.00, 18, 'DEP-PES-003', '2025-11-15 08:00:00', TRUE),
(4, 4, 'Cuerda para Saltar', 'Cuerda de alta velocidad', 15.00, 5.00, 100, 'DEP-CUE-004', '2025-11-15 08:00:00', TRUE),
-- Juguetes
(5, 5, 'Rompecabezas 1000 piezas', 'Paisaje montañoso', 25.00, 10.00, 40, 'JUG-ROM-001', '2025-12-01 08:00:00', TRUE),
(5, 5, 'Coche RC Todo Terreno', 'Coche a control remoto 4x4', 75.00, 35.00, 20, 'JUG-COC-002', '2025-12-01 08:00:00', TRUE),
(5, 5, 'Set Bloques Construcción', 'Caja con 500 piezas creativas', 45.00, 20.00, 30, 'JUG-BLO-003', '2025-12-10 08:00:00', TRUE),
(5, 5, 'Muñeca Coleccionable', 'Edición especial limitada', 150.00, 80.00, 2, 'JUG-MUN-004', '2025-12-10 08:00:00', TRUE); -- Stock crítico intencional

-- 5. Ventas (15 transacciones, algunas con múltiples productos. Los totales son precisos)
INSERT INTO ventas (id_cliente, fecha_venta, estado, total) VALUES
(1, '2025-07-01 10:30:00', 'Entregado', 1200.00), -- Venta 1
(2, '2025-08-15 14:20:00', 'Entregado', 650.00),  -- Venta 2
(3, '2025-09-10 09:45:00', 'Entregado', 105.00),  -- Venta 3
(1, '2025-11-20 16:15:00', 'Entregado', 800.00),  -- Venta 4 (Compra repetida VIP)
(4, '2025-12-05 11:10:00', 'Entregado', 50.00),   -- Venta 5
(5, '2026-01-20 18:30:00', 'Entregado', 150.00),  -- Venta 6
(6, '2026-02-15 08:45:00', 'Entregado', 85.00),   -- Venta 7
(4, '2026-03-10 13:20:00', 'Entregado', 2400.00), -- Venta 8 (VIP alto valor)
(7, '2026-04-05 15:50:00', 'Enviado', 120.00),    -- Venta 9
(8, '2026-05-12 10:10:00', 'Enviado', 45.00),     -- Venta 10
(9, '2026-06-18 09:30:00', 'Procesando', 110.00), -- Venta 11
(1, '2026-07-05 14:00:00', 'Procesando', 240.00), -- Venta 12 (Tercera compra VIP)
(10, '2026-08-01 11:20:00', 'Pendiente de Pago', 800.00), -- Venta 13
(2, '2026-08-20 16:40:00', 'Cancelado', 90.00),   -- Venta 14 (Compra repetida, pero cancelada)
(3, '2026-09-05 10:15:00', 'Pendiente de Pago', 70.00);   -- Venta 15 (Compra repetida)

-- 6. Detalle_Ventas (30 registros que enlazan ventas con productos respetando los precios)
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario_congelado) VALUES
-- Venta 1 (Total: 1200)
(1, 1, 1, 1200.00), -- Laptop
-- Venta 2 (Total: 650)
(2, 3, 2, 150.00),  -- Auriculares (300)
(2, 4, 1, 350.00),  -- Monitor (350)
-- Venta 3 (Total: 105)
(3, 5, 3, 20.00),   -- Camiseta (60)
(3, 6, 1, 45.00),   -- Pantalon (45)
-- Venta 4 (Total: 800)
(4, 2, 1, 800.00),  -- Smartphone
-- Venta 5 (Total: 50)
(5, 13, 1, 35.00),  -- Balon
(5, 16, 1, 15.00),  -- Cuerda
-- Venta 6 (Total: 150)
(6, 18, 2, 75.00),  -- Coche RC
-- Venta 7 (Total: 85)
(7, 7, 1, 85.00),   -- Chaqueta
-- Venta 8 (Total: 2400)
(8, 1, 2, 1200.00), -- Laptop (2400)
-- Venta 9 (Total: 120)
(9, 10, 2, 60.00),  -- Lampara (120)
-- Venta 10 (Total: 45)
(10, 19, 1, 45.00), -- Set Bloques
-- Venta 11 (Total: 110)
(11, 12, 1, 110.00),-- Licuadora
-- Venta 12 (Total: 240)
(12, 14, 2, 120.00),-- Raqueta
-- Venta 13 (Total: 800)
(13, 2, 1, 800.00), -- Smartphone
-- Venta 14 (Total: 90)
(14, 8, 1, 90.00),  -- Zapatillas
-- Venta 15 (Total: 70)
(15, 11, 1, 30.00), -- Sarten (30)
(15, 5, 2, 20.00);  -- Camiseta (40)