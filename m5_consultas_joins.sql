-- Motor utilizado: SQL Server (SSMS)
/* =====================================================================
   Pre-entrega Módulo 5 - Consultas con JOINs para el proyecto
   Alumna: Macarena Llorens Pastoriza
   Base: Ventas_Tech_DB (creada con ventas_tech_db.sql)

   Mi esquema: ventas (hechos) -> clientes y productos
               productos       -> categorias
   Como dimensión geográfica uso la ciudad del cliente, que ya está en
   la tabla clientes, así que no hizo falta cambiar el script del M3.
   ===================================================================== */

USE Ventas_Tech_DB;
GO

-- Consulta 1: Vista base del proyecto (INNER JOIN)
-- Propósito: tener en una sola fila cada venta con su cliente, su ciudad,
-- el producto y la categoría. La guardo como vista para usarla como
-- fuente principal en Power BI. Para agrupar sirve categoria y para
-- filtrar ciudad y fecha_venta.
-- Uso INNER JOIN porque solo quiero ventas con cliente y producto válidos.
CREATE OR ALTER VIEW vw_ventas_detalle AS
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre                        AS cliente,
    c.ciudad,
    p.nombre_producto               AS producto,
    cat.nombre_categoria            AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario  AS total_venta
FROM ventas v
INNER JOIN clientes   c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  p   ON v.id_producto  = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria;
GO

SELECT * FROM vw_ventas_detalle ORDER BY fecha_venta;
-- Hallazgo: salen las 10 ventas ($6.444), ninguna se perdió en el cruce.
-- Computación (Laptop Pro 15 y Monitor 4K 27) factura $4.950, el 77% del total.


-- Consulta 2: Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron, para que
-- CRM los contacte. El LEFT JOIN trae todos los clientes y los que no
-- tienen ventas quedan con NULL, que es lo que filtro con IS NULL.
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;
-- Hallazgo: 0 de los 5 clientes registrados están sin compras: todos
-- compraron 2 veces. Para CRM no hay clientes inactivos que recuperar,
-- el foco tendría que estar en conseguir clientes nuevos.


-- Consulta 3: Productos sin ventas (LEFT JOIN)
-- Propósito: identificar productos del catálogo sin movimiento, para que
-- el área de producto decida si los promociona o los da de baja.
SELECT
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos p
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
LEFT JOIN  ventas v       ON p.id_producto  = v.id_producto
WHERE v.id_venta IS NULL;
-- Hallazgo: 0 de los 6 productos están sin ventas: todo el catálogo se
-- movió. Para producto no hay artículos para dar de baja; el que menos
-- factura es Auriculares BT Pro ($360), que conviene seguir de cerca.


-- Prueba de las consultas 2 y 3
-- Propósito: como las dos dieron 0 filas, comprobar que realmente
-- funcionan. Agrego un cliente y un producto sin ventas DENTRO de una
-- transacción, corro las consultas y hago ROLLBACK: la base queda igual
-- que antes y el script del M3 no cambia.
BEGIN TRANSACTION;

    INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro)
    VALUES (6, 'Sofía Díaz', 'sofia@mail.com', 'Salta', '2024-03-20');

    INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo)
    VALUES (7, 'Pendrive 64GB', 4, 15.00, 50, 1);

    SELECT c.nombre, c.email, c.fecha_registro
    FROM clientes c
    LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
    WHERE v.id_venta IS NULL;

    SELECT p.nombre_producto, cat.nombre_categoria AS categoria, p.precio
    FROM productos p
    INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
    LEFT JOIN  ventas v       ON p.id_producto  = v.id_producto
    WHERE v.id_venta IS NULL;

ROLLBACK TRANSACTION;
-- Hallazgo: con los datos de prueba aparecen Sofía Díaz y Pendrive 64GB,
-- así que las consultas detectan bien a quien no tiene ventas.


-- Consulta 4: Consolidado por canal (UNION ALL)
-- Propósito: comparar cuánto se vendió en cada período. La columna canal
-- no existe en mis tablas, la creo con un texto fijo en cada SELECT.
-- Mi criterio: semana 1 (5 al 10 de marzo) y semana 2 (11 al 15 de marzo).
-- Uso UNION ALL y no UNION para que no se borre ninguna venta que
-- coincida con otra en todos sus valores: cada venta cuenta una vez.
SELECT
    canal,
    COUNT(*)    AS cantidad_ventas,
    SUM(total)  AS total_canal
FROM (
    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Semana 1 (5 al 10/03)' AS canal
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-05' AND '2024-03-10'

    UNION ALL

    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Semana 2 (11 al 15/03)' AS canal
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-11' AND '2024-03-15'
) AS consolidado
GROUP BY canal
ORDER BY canal;
-- Hallazgo: las dos semanas tuvieron 5 ventas, pero la semana 1 facturó
-- $3.620 y la semana 2 $2.824 (22% menos). No bajaron las compras, bajó
-- lo que se gastó en cada una.
