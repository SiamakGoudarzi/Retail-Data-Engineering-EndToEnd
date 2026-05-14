/* ============================================================
   RETAIL_DWH – Data Warehouse (OLAP)
   Enthält: Dimensionstabellen + Faktentabelle
   ============================================================ */

IF DB_ID('Retail_DWH') IS NOT NULL
    DROP DATABASE Retail_DWH;
GO

CREATE DATABASE Retail_DWH;
GO

USE Retail_DWH;
GO

/* ------------------------------
   Dimension: Product_Dim (SCD2)
   Zweck: Historisierte Produktdaten
   ------------------------------ */
CREATE TABLE Product_Dim (
    Product_Dim_ID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    StockCode NVARCHAR(50),
    Description NVARCHAR(255),
    CategoryName NVARCHAR(100),
    CurrentPrice DECIMAL(10,2),
    Start_Date DATE,
    End_Date DATE,
    IsActive BIT
);

/* ------------------------------
   Dimension: Customer_Dim
   Zweck: Kundeninformationen
   ------------------------------ */
CREATE TABLE Customer_Dim (
    Customer_Dim_ID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    CountryName NVARCHAR(100),
    Start_Date DATE,
    End_Date DATE,
    IsActive BIT
);

/* ------------------------------
   Dimension: Store_Dim
   Zweck: Filialinformationen
   ------------------------------ */
CREATE TABLE Store_Dim (
    Store_Dim_ID INT IDENTITY(1,1) PRIMARY KEY,
    StoreID INT,
    StoreName NVARCHAR(100),
    CountryName NVARCHAR(100)
);

/* ------------------------------
   Dimension: Employee_Dim
   Zweck: Mitarbeiterinformationen
   ------------------------------ */
CREATE TABLE Employee_Dim (
    Employee_Dim_ID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    FullName NVARCHAR(100),
    StoreName NVARCHAR(100)
);

/* ------------------------------
   Dimension: Time_Dim
   Zweck: Zeitdimension für Analysen
   ------------------------------ */
CREATE TABLE Time_Dim (
    Time_Dim_ID INT IDENTITY(1,1) PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Month INT,
    Day INT,
    Quarter INT,
    Week INT,
    Weekday NVARCHAR(20),
    Hour INT
);

/* ------------------------------
   Faktentabelle: Sales_Fact
   Zweck: Zentrale Faktentabelle für Verkaufsanalysen
   ------------------------------ */
CREATE TABLE Sales_Fact (
    Sales_Fact_ID INT IDENTITY(1,1) PRIMARY KEY,
    Product_Dim_ID INT NOT NULL,
    Customer_Dim_ID INT NOT NULL,
    Store_Dim_ID INT NULL,
    Employee_Dim_ID INT NULL,
    Time_Dim_ID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    TotalPrice AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_SalesFact_ProductDim FOREIGN KEY (Product_Dim_ID)
        REFERENCES Product_Dim(Product_Dim_ID),
    CONSTRAINT FK_SalesFact_CustomerDim FOREIGN KEY (Customer_Dim_ID)
        REFERENCES Customer_Dim(Customer_Dim_ID),
    CONSTRAINT FK_SalesFact_StoreDim FOREIGN KEY (Store_Dim_ID)
        REFERENCES Store_Dim(Store_Dim_ID),
    CONSTRAINT FK_SalesFact_EmployeeDim FOREIGN KEY (Employee_Dim_ID)
        REFERENCES Employee_Dim(Employee_Dim_ID),
    CONSTRAINT FK_SalesFact_TimeDim FOREIGN KEY (Time_Dim_ID)
        REFERENCES Time_Dim(Time_Dim_ID)
);
