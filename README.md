# RetailPro – Proyecto de Data Analytics

Proyecto de análisis de ventas para **RetailPro**, una distribuidora de tecnología. Incluye el diseño de una base de datos relacional, consultas SQL de negocio y modelos de Power BI para la visualización de resultados.

**Alumna:** Macarena Llorens Pastoriza · Curso de Data Analytics, Coderhouse

## Descripción

El objetivo del proyecto es analizar las ventas de RetailPro para entender qué productos, categorías y clientes generan más facturación, y construir un modelo de datos que permita hacer ese análisis de forma ordenada y repetible.

## Herramientas utilizadas

- **SQL Server** y **SQL Server Management Studio (SSMS)**: creación de la base y consultas
- **Power BI Desktop**: limpieza de datos (Power Query), modelado y medidas DAX
- **Excel**: dataset del pipeline ETL (`Pipeline_ETL_Dataset.xlsx`)
- **GitHub**: control de versiones y entrega
- **Claude.ai** (versión gratuita): revisión de código, borrador de este README e ideas de insights, todo revisado por mí

## Estructura del repositorio

| Archivo | Módulo | Descripción |
|---|---|---|
| `ventas_tech_db.sql` | M3 | Crea la base `Ventas_Tech_DB` (categorias, clientes, productos, ventas) con PK y FK, carga los 25 registros y valida |
| `m4_consultas_negocio.sql` | M4 | Resumen ejecutivo mensual, top 5 de productos, clientes recurrentes y meses contra el promedio |
| `m5_consultas_joins.sql` | M5 | Vista base `vw_ventas_detalle` (INNER JOIN), clientes y productos sin ventas |
| `Pipeline_ETL_Llorens_Macarena..pbix` | M6 | Pipeline ETL en Power Query: limpieza de duplicados y nulos, tipos de dato y Merge |
| `Llorens_Macarena_Checkpoint2..pbix` | M8 | Modelo estrella, tabla calendario y medidas DAX (YTD, año anterior, % crecimiento) |

## Cómo ejecutar los scripts

### Requisitos
- SQL Server (sirve la edición Express o Developer, que son gratis)
- SQL Server Management Studio
- Power BI Desktop

### Pasos
1. Descargá los archivos desde https://github.com/macallorens12-ops/retailpro-data-analytics (botón **Code → Download ZIP**) o cloná el repositorio:
   ```bash
   git clone https://github.com/macallorens12-ops/retailpro-data-analytics.git
   ```
2. Abrí SSMS y conectate a tu instancia de SQL Server.
3. Ejecutá `ventas_tech_db.sql` completo (F5). Crea la base si no existe, así que se puede correr varias veces. Las consultas de validación del final tienen que devolver 4 categorías, 5 clientes, 6 productos y 10 ventas.
4. Ejecutá `m4_consultas_negocio.sql` y después `m5_consultas_joins.sql` (este último crea la vista `vw_ventas_detalle`).
5. Abrí los `.pbix` en Power BI Desktop. **Ojo:** no se conectan a SQL Server, cargan el Excel del curso `Pipeline_ETL_Dataset.xlsx`. Si Power BI no lo encuentra, andá a **Transformar datos → Configuración de origen de datos → Cambiar origen** y elegí la ruta donde lo guardaste.

## Hallazgos principales (base SQL, marzo 2024)

- Se facturaron **$6.444** en 10 pedidos, con un ticket promedio de $644,40. La mediana es $385, porque las laptops inflan el promedio.
- La **Laptop Pro 15** sola es el 56% de la facturación y la categoría **Computación** llega al 77%.
- El **Mouse Inalámbrico** es el que más unidades vende (13) pero factura solo el 6%.
- Los 5 clientes compraron 2 veces cada uno: no hay clientes inactivos.
