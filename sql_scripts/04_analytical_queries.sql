/* ============================================================
RETAIL DATA WAREHOUSE - ANALYTICAL QUERIES (BI INSIGHTS)
Description: These queries extract business value from the DWH 
             using the Star Schema (Sales_Fact and Dimensions).
============================================================
*/

USE Retail_DWH;
GO

-- 1. Regional Performance Analysis
-- Objective: Rank stores and countries by total revenue.
SELECT
    s.CountryName AS Land,
    s.StoreName AS Filiale,
    FORMAT(SUM(f.TotalPrice), 'N0') AS Filialumsatz
FROM Sales_Fact f
JOIN Store_Dim s ON f.Store_Dim_ID = s.Store_Dim_ID
GROUP BY s.CountryName, s.StoreName
ORDER BY SUM(f.TotalPrice) DESC;


-- 2. Product Category Performance
-- Objective: Identify top-performing product categories.
SELECT
    p.CategoryName AS Kategorie,
    SUM(f.Quantity) AS Verkaufte_Einheiten,
    FORMAT(SUM(f.TotalPrice), 'N0') AS Gesamtumsatz
FROM Sales_Fact f
JOIN Product_Dim p ON f.Product_Dim_ID = p.Product_Dim_ID
GROUP BY p.CategoryName
ORDER BY SUM(f.TotalPrice) DESC;


-- 3. Monthly Sales Trends
-- Objective: Monitor revenue growth and transaction volume over time.
SELECT
    t.Year AS Jahr,
    t.Month AS Monat,
    FORMAT(SUM(f.TotalPrice), 'N0') AS Monatsumsatz,
    COUNT(f.Sales_Fact_ID) AS Anzahl_Transaktionen
FROM Sales_Fact f
JOIN Time_Dim t ON f.Time_Dim_ID = t.Time_Dim_ID
GROUP BY t.Year, t.Month
ORDER BY t.Year, t.Month;


-- 4. Customer Segmentation (RFM Analysis)
-- Objective: Classify customers into segments based on Recency, Frequency, and Monetary value.
WITH CustomerRFM AS (
    SELECT
        c.CustomerID,
        DATEDIFF(DAY, MAX(t.FullDate), GETDATE()) AS Recency,
        COUNT(f.Sales_Fact_ID) AS Frequency,
        SUM(f.TotalPrice) AS MonetaryValue
    FROM Sales_Fact f
    JOIN Customer_Dim c ON f.Customer_Dim_ID = c.Customer_Dim_ID
    JOIN Time_Dim t ON f.Time_Dim_ID = t.Time_Dim_ID
    GROUP BY c.CustomerID
)
SELECT
    CustomerID,
    Recency AS Tage_Seit_Letztem_Kauf,
    Frequency AS Kaufhaeufigkeit,
    MonetaryValue AS Gesamtwert,
    CASE
        WHEN Recency < 30 AND Frequency > 5 THEN 'A-Kunde (Aktiv)'
        WHEN Recency > 180 THEN 'Inaktivitätsrisiko'
        WHEN MonetaryValue > 2000 THEN 'Premium-Kunde'
        ELSE 'Standard'
    END AS Kunden_Segment
FROM CustomerRFM
ORDER BY MonetaryValue DESC;


-- 5. Peak Sales Hours Analysis
-- Objective: Identify the busiest hours to optimize store staffing.
SELECT
    t.Hour AS Stunde,
    COUNT(f.Sales_Fact_ID) AS Verkaufsanzahl,
    FORMAT(SUM(f.TotalPrice), 'N0') AS Umsatz_Pro_Stunde
FROM Sales_Fact f
JOIN Time_Dim t ON f.Time_Dim_ID = t.Time_Dim_ID
GROUP BY t.Hour
ORDER BY t.Hour;