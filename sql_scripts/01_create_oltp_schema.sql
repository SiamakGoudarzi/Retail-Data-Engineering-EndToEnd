/* ============================================================
   RETAIL_OLTP – Operationale Datenbank (OLTP)
   Enthält: Länder, Kunden, Kategorien, Produkte, Stores, Mitarbeiter,
   Verkaufsbelege (Header + Details)
   ============================================================ */

IF DB_ID('Retail_OLTP') IS NOT NULL
    DROP DATABASE Retail_OLTP;
GO

CREATE DATABASE Retail_OLTP;
GO

USE Retail_OLTP;
GO

/* ------------------------------
   Tabelle: Countries
   Zweck: Länder für Kunden und Stores
   ------------------------------ */
CREATE TABLE Countries (
    CountryID INT IDENTITY(1,1) PRIMARY KEY,
    CountryName NVARCHAR(100) NOT NULL
);

/* ------------------------------
   Tabelle: Customers
   Zweck: Kundenstammdaten
   ------------------------------ */
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CountryID INT NOT NULL,
    CONSTRAINT FK_Customers_Countries FOREIGN KEY (CountryID)
        REFERENCES Countries(CountryID)
);

/* ------------------------------
   Tabelle: Categories
   Zweck: Produktkategorien
   ------------------------------ */
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL
);

/* ------------------------------
   Tabelle: Products
   Zweck: Produktstammdaten
   ------------------------------ */
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    StockCode NVARCHAR(50) UNIQUE NOT NULL,
    Description NVARCHAR(255),
    CategoryID INT NOT NULL,
    CurrentPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
);

/* ------------------------------
   Tabelle: Stores
   Zweck: Filialen (10 Beispiel-Filialen)
   ------------------------------ */
CREATE TABLE Stores (
    StoreID INT IDENTITY(1,1) PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    CountryID INT NOT NULL,
    CONSTRAINT FK_Stores_Countries FOREIGN KEY (CountryID)
        REFERENCES Countries(CountryID)
);

/* ------------------------------
   Tabelle: Employees
   Zweck: Mitarbeiter (20 Beispiel-Mitarbeiter)
   ------------------------------ */
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    StoreID INT NOT NULL,
    CONSTRAINT FK_Employees_Stores FOREIGN KEY (StoreID)
        REFERENCES Stores(StoreID)
);

/* ------------------------------
   Tabelle: SalesHeaders
   Zweck: Verkaufsbelege (Kopf)
   ------------------------------ */
CREATE TABLE SalesHeaders (
    InvoiceNo NVARCHAR(20) PRIMARY KEY,
    InvoiceDate DATETIME NOT NULL,
    CustomerID INT NOT NULL,
    StoreID INT NULL,
    EmployeeID INT NULL,
    CONSTRAINT FK_SalesHeaders_Customers FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID),
    CONSTRAINT FK_SalesHeaders_Stores FOREIGN KEY (StoreID)
        REFERENCES Stores(StoreID),
    CONSTRAINT FK_SalesHeaders_Employees FOREIGN KEY (EmployeeID)
        REFERENCES Employees(EmployeeID)
);

/* ------------------------------
   Tabelle: SalesDetails
   Zweck: Verkaufspositionen (Detail)
   ------------------------------ */
CREATE TABLE SalesDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNo NVARCHAR(20) NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_SalesDetails_SalesHeaders FOREIGN KEY (InvoiceNo)
        REFERENCES SalesHeaders(InvoiceNo),
    CONSTRAINT FK_SalesDetails_Products FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
);

/* ============================================================
   Beispiel-Daten einfügen
   ============================================================ */

-- Länder
INSERT INTO Countries (CountryName)
VALUES ('Deutschland'), ('Vereinigtes Königreich'), ('Frankreich'),
       ('Spanien'), ('Italien');

-- Stores (10 Filialen)
INSERT INTO Stores (StoreName, CountryID)
VALUES
('Berlin Store Mitte', 1),
('Berlin Store Neukölln', 1),
('Hamburg City Store', 1),
('München Central Store', 1),
('Köln Rhein Store', 1),
('London Central Store', 2),
('London West Store', 2),
('Paris Center Store', 3),
('Madrid Gran Via Store', 4),
('Rom City Store', 5);

-- Employees (20 Mitarbeiter)
INSERT INTO Employees (FullName, StoreID)
VALUES
('Anna Schmidt', 1), ('Jonas Weber', 1),
('Laura Klein', 2), ('Michael Braun', 2),
('Sophie Wagner', 3), ('Felix Hoffmann', 3),
('Lena Fischer', 4), ('David Richter', 4),
('Julia Vogel', 5), ('Thomas Keller', 5),
('Emily Johnson', 6), ('Oliver Smith', 6),
('Chloe Brown', 7), ('Jack Wilson', 7),
('Marie Dubois', 8), ('Pierre Martin', 8),
('Carlos Garcia', 9), ('Lucia Fernandez', 9),
('Marco Rossi', 10), ('Giulia Bianchi', 10);
