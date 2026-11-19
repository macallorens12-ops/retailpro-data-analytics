-- Motor utilizado: SQL Server (SSMS)
/* =====================================================================
   Pre-entrega Módulo 4 - Consultas SQL de negocio
   Alumna: Macarena Llorens Pastoriza
   Base: Ventas_Tech_DB (creada con ventas_tech_db.sql)

   Trabajo solo sobre la tabla ventas, con los ids. El total de cada
   venta lo calculo como cantidad * precio_unitario.

   Nota: la consigna dice EXTRACT(MONTH FROM fecha_venta), que es la
   forma de PostgreSQL. En SQL Server lo mismo se escribe MONTH(fecha_venta).
   Agrupo también por YEAR para que, si la base crece, no se mezclen
   meses iguales de años distintos (marzo 2024 con marzo 2025).
   ===================================================================== */

USE Ventas_Tech_DB;
GO

-- =====================================================================
-- Consulta 1 - Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- =====================================================================
SELECT
    YEAR(fecha_venta)                                       AS anio,
    MONTH(fecha_venta)                                      AS mes,
    SUM(cantidad * precio_unitario)                         AS total_facturado,
    COUNT(*)                                                AS cantidad_pedidos,
    CAST(AVG(cantidad * precio_unitario) AS DECIMAL(10,2))  AS ticket_promedio
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio, mes;
-- Resultado: 2024 / marzo -> $6.444 facturados, 10 pedidos, ticket $644,40


-- =====================================================================
-- Consulta 2 - Ranking de productos (Top 5 por facturación)
-- En SQL Server no existe LIMIT: se usa TOP 5 al principio del SELECT.
-- =====================================================================
SELECT TOP 5
    id_producto,
    SUM(cantidad)                    AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;
-- Resultado: 1 ($3.600), 3 ($1.350), 5 ($390), 6 ($380), 2 ($364).
-- Queda afuera el producto 4 ($360).


-- =====================================================================
-- Consulta 3 - Clientes recurrentes
-- Clientes con más de un pedido, con cuántos pedidos y cuánto gastaron.
-- El filtro va en HAVING y no en WHERE porque usa COUNT(*): filtra los
-- grupos ya armados, no las filas sueltas.
-- =====================================================================
SELECT
    id_cliente,
    COUNT(*)                         AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;
-- Resultado: los 5 clientes, con 2 pedidos cada uno.
-- Cliente 1 $2.640, cliente 5 $2.100, cliente 3 $674, cliente 2 $520, cliente 4 $510.


-- =====================================================================
-- Consulta 4 - Meses por encima / por debajo del promedio
-- Primero calculo el total de cada mes (ventas_por_mes) y después
-- comparo cada mes contra el promedio de esos totales mensuales.
-- Ojo: es el promedio de los TOTALES MENSUALES, no de las ventas sueltas.
-- Agregué un tercer caso ('En el promedio') para cuando el mes da igual.
-- =====================================================================
WITH ventas_por_mes AS (
    SELECT
        YEAR(fecha_venta)               AS anio,
        MONTH(fecha_venta)              AS mes,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
)
SELECT
    anio,
    mes,
    total_facturado,
    (SELECT AVG(total_facturado) FROM ventas_por_mes) AS promedio_mensual,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM ventas_por_mes) THEN 'Por encima'
        WHEN total_facturado < (SELECT AVG(total_facturado) FROM ventas_por_mes) THEN 'Por debajo'
        ELSE 'En el promedio'
    END AS comparacion
FROM ventas_por_mes
ORDER BY anio, mes;
-- Resultado: hoy todas las ventas son de marzo 2024, así que hay un solo
-- mes y su total es igual al promedio ('En el promedio'). La consulta
-- queda lista para cuando se carguen más meses.

-- Consulta 4b (extra) - La misma lógica por día, para ver que el CASE
-- funciona con los datos que hay hoy.
WITH ventas_por_dia AS (
    SELECT fecha_venta, SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY fecha_venta
)
SELECT
    fecha_venta,
    total_facturado,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM ventas_por_dia) THEN 'Por encima'
        WHEN total_facturado < (SELECT AVG(total_facturado) FROM ventas_por_dia) THEN 'Por debajo'
        ELSE 'En el promedio'
    END AS comparacion
FROM ventas_por_dia
ORDER BY fecha_venta;
-- Resultado: promedio diario $644,40. Solo 3 días quedan por encima
-- (5/3 $2.400, 12/3 $1.200 y 15/3 $900) y los otros 7 por debajo.


-- =====================================================================
-- HALLAZGOS
-- =====================================================================
-- 1. El producto 1 (Laptop Pro 15) genera $3.600 de los $6.444 del mes,
--    o sea el 56% de la facturación con solo 3 unidades. Si le sumo el
--    producto 3 (Monitor 4K) la categoría Computación llega al 77%.
--    Conviene cuidar el stock de esos dos: hay 15 laptops y 12 monitores.
--
-- 2. El producto que más unidades vende es el 2 (Mouse Inalámbrico, 13
--    unidades), pero factura apenas $364 (6%) y ni siquiera llega al
--    top 3. Vender muchas unidades no es lo mismo que facturar mucho:
--    sirve como producto para sumar en combo con una laptop.
--
-- 3. Los 5 clientes compraron 2 veces, pero el gasto está muy concentrado:
--    los clientes 1 y 5 (los dos que compraron laptop) suman $4.740, el
--    74% del total. Por eso el ticket promedio ($644,40) está inflado:
--    7 de las 10 ventas son de menos de $460 y la venta del medio ronda
--    los $385. Para el seguimiento comercial conviene mirar la mediana
--    además del promedio.
