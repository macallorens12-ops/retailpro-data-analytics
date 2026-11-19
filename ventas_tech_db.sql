-- Motor utilizado: SQL Server (SSMS)
/* =====================================================================
   Checkpoint Módulo 3 - Script SQL de la base Ventas_Tech_DB
   Alumna: Macarena Llorens Pastoriza

   Modelo:
   categorias (1) ---- (N) productos (1) ---- (N) ventas (N) ---- (1) clientes

   El script tiene 4 secciones: DROP, CREATE, INSERT y VALIDACIÓN.
   Se puede correr las veces que haga falta sin errores.
   ===================================================================== */

-- Creo la base solo si todavía no existe (así el script es repetible)
IF DB_ID('Ventas_Tech_DB') IS NULL
    CREATE DATABASE Ventas_Tech_DB;
GO
USE Ventas_Tech_DB;
GO


-- === SECCIÓN 1: DROP ===
-- Borro en orden inverso a las dependencias: primero ventas, que tiene
-- las FK hacia clientes y productos, y al final categorias, de la que
-- depende productos. Si lo hiciera al revés, SQL Server no me dejaría
-- borrar una tabla que otra está referenciando.
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS categorias;
GO


-- === SECCIÓN 2: CREATE ===
-- Primero las tablas que no dependen de nadie (dimensiones) y al final
-- ventas (hechos), porque sus FK necesitan que las otras ya existan.

-- Categorías en su propia tabla y no como texto dentro de productos:
-- así el nombre de cada categoría se guarda una sola vez (3NF).
CREATE TABLE categorias (
    id_categoria      INT           PRIMARY KEY,
    nombre_categoria  VARCHAR(50)   NOT NULL,
    descripcion       VARCHAR(200)
);

CREATE TABLE clientes (
    id_cliente      INT           PRIMARY KEY,
    nombre          VARCHAR(100)  NOT NULL,
    email           VARCHAR(100)  UNIQUE,      -- no puede haber dos clientes con el mismo mail
    ciudad          VARCHAR(50),
    fecha_registro  DATE          NOT NULL
);

CREATE TABLE productos (
    id_producto      INT            PRIMARY KEY,
    nombre_producto  VARCHAR(100)   NOT NULL,
    id_categoria     INT            FOREIGN KEY REFERENCES categorias(id_categoria),
    precio           DECIMAL(10,2)  NOT NULL,  -- DECIMAL y no FLOAT para no perder centavos
    stock            INT            DEFAULT 0,
    activo           BIT            DEFAULT 1  -- 1 = activo, 0 = dado de baja
);

-- Tabla de hechos: cada fila es una venta.
-- Guardo precio_unitario (el precio al que se vendió ese día) aunque el
-- producto ya tenga precio, porque el precio de lista puede cambiar y la
-- venta tiene que conservar el valor histórico.
CREATE TABLE ventas (
    id_venta         INT            PRIMARY KEY,
    id_cliente       INT            FOREIGN KEY REFERENCES clientes(id_cliente),
    id_producto      INT            FOREIGN KEY REFERENCES productos(id_producto),
    cantidad         INT            NOT NULL,
    precio_unitario  DECIMAL(10,2)  NOT NULL,
    fecha_venta      DATE           NOT NULL
);
GO


-- === SECCIÓN 3: INSERT ===
-- Mismo orden que el CREATE: primero categorias y clientes, después
-- productos (que necesita categorias) y al final ventas (que necesita
-- clientes y productos). Escribo las columnas en cada INSERT para que no
-- dependa del orden de las columnas en la tabla.

-- categorias: 4 registros
INSERT INTO categorias (id_categoria, nombre_categoria, descripcion) VALUES
  (1, 'Computación',    'Laptops, PCs y monitores'),
  (2, 'Accesorios',     'Periféricos y complementos'),
  (3, 'Audio',          'Auriculares y parlantes'),
  (4, 'Almacenamiento', 'Discos y memorias');

-- clientes: 5 registros
INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro) VALUES
  (1, 'María López',  'maria@mail.com',  'Buenos Aires', '2024-01-05'),
  (2, 'Carlos Ruiz',  'carlos@mail.com', 'Córdoba',      '2024-01-10'),
  (3, 'Ana Gómez',    'ana@mail.com',    'Rosario',      '2024-02-01'),
  (4, 'Pedro Sanz',   'pedro@mail.com',  'Mendoza',      '2024-02-15'),
  (5, 'Laura Torres', 'laura@mail.com',  'Tucumán',      '2024-03-01');

-- productos: 6 registros
INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo) VALUES
  (1, 'Laptop Pro 15',      1, 1200.00, 15, 1),
  (2, 'Mouse Inalámbrico',  2,   28.00, 80, 1),
  (3, 'Monitor 4K 27',      1,  450.00, 12, 1),
  (4, 'Auriculares BT Pro', 3,  120.00, 35, 1),
  (5, 'SSD Externo 1TB',    4,  130.00, 18, 1),
  (6, 'Teclado Mecánico',   2,   95.00, 40, 1);

-- ventas: 10 registros
INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) VALUES
  ( 1, 1, 1, 2, 1200.00, '2024-03-05'),
  ( 2, 2, 2, 5,   28.00, '2024-03-06'),
  ( 3, 3, 3, 1,  450.00, '2024-03-07'),
  ( 4, 1, 4, 2,  120.00, '2024-03-08'),
  ( 5, 4, 5, 3,  130.00, '2024-03-10'),
  ( 6, 2, 6, 4,   95.00, '2024-03-11'),
  ( 7, 5, 1, 1, 1200.00, '2024-03-12'),
  ( 8, 3, 2, 8,   28.00, '2024-03-13'),
  ( 9, 4, 4, 1,  120.00, '2024-03-14'),
  (10, 5, 3, 2,  450.00, '2024-03-15');
GO


-- === SECCIÓN 4: VALIDACIÓN ===
SELECT * FROM categorias;   -- esperado: 4 filas
SELECT * FROM clientes;     -- esperado: 5 filas
SELECT * FROM productos;    -- esperado: 6 filas
SELECT * FROM ventas;       -- esperado: 10 filas

-- Prueba de integridad (la dejo comentada para que el script corra entero):
-- esta venta usa el cliente 99, que no existe. Al ejecutarla, SQL Server
-- tiene que dar error por la FOREIGN KEY. Eso confirma que no se puede
-- vender a un cliente ni un producto que no existen.
-- INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta)
-- VALUES (11, 99, 1, 1, 1200.00, '2024-03-16');
