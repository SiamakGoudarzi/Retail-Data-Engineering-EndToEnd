import pyodbc
from datetime import datetime

# 1. Datenbankverbindung konfigurieren
conn_oltp_str = r"Driver={SQL Server};Server=RZPC-0-155\SQLEXPRESS;Database=Retail_OLTP;Trusted_Connection=yes;"
conn_dwh_str = r"Driver={SQL Server};Server=RZPC-0-155\SQLEXPRESS;Database=Retail_DWH;Trusted_Connection=yes;"

try:
    conn_oltp = pyodbc.connect(conn_oltp_str)
    conn_dwh = pyodbc.connect(conn_dwh_str)
    cursor_oltp = conn_oltp.cursor()
    cursor_dwh = conn_dwh.cursor()
    print("Verbindung zu OLTP und DWH erfolgreich!")
except Exception as e:
    print(f"Verbindungsfehler: {e}")
    exit()

# ---------------------------------------------------------
# Schritt 1 & 2: Statische Dimensionen (Store, Employee)
# ---------------------------------------------------------
print("ETL: Statische Dimensionen werden geladen...")

# Dim_Store
cursor_oltp.execute("SELECT s.StoreID, s.StoreName, c.CountryName FROM Stores s JOIN Countries c ON s.CountryID = c.CountryID")
for row in cursor_oltp.fetchall():
    cursor_dwh.execute("""
        IF NOT EXISTS (SELECT 1 FROM Store_Dim WHERE StoreID = ?) 
        INSERT INTO Store_Dim (StoreID, StoreName, CountryName) VALUES (?, ?, ?)""", 
        row.StoreID, row.StoreID, row.StoreName, row.CountryName)

# Dim_Employee
cursor_oltp.execute("SELECT e.EmployeeID, e.FullName, s.StoreName FROM Employees e JOIN Stores s ON e.StoreID = s.StoreID")
for row in cursor_oltp.fetchall():
    cursor_dwh.execute("""
        IF NOT EXISTS (SELECT 1 FROM Employee_Dim WHERE EmployeeID = ?) 
        INSERT INTO Employee_Dim (EmployeeID, FullName, StoreName) VALUES (?, ?, ?)""", 
        row.EmployeeID, row.EmployeeID, row.FullName, row.StoreName)

# ---------------------------------------------------------
# Schritt 3: Customer_Dim (SCD Typ 2 Implementierung)
# ---------------------------------------------------------
print("ETL: Customer_Dim (SCD 2) wird verarbeitet...")
cursor_oltp.execute("SELECT c.CustomerID, co.CountryName FROM Customers c JOIN Countries co ON c.CountryID = co.CountryID")
for row in cursor_oltp.fetchall():
    cursor_dwh.execute("SELECT CountryName FROM Customer_Dim WHERE CustomerID = ? AND IsActive = 1", row.CustomerID)
    existing_cust = cursor_dwh.fetchone()

    if not existing_cust:
        cursor_dwh.execute("INSERT INTO Customer_Dim (CustomerID, CountryName, Start_Date, IsActive) VALUES (?, ?, GETDATE(), 1)", 
                           row.CustomerID, row.CountryName)
    elif existing_cust[0] != row.CountryName:
        cursor_dwh.execute("UPDATE Customer_Dim SET IsActive = 0, End_Date = GETDATE() WHERE CustomerID = ? AND IsActive = 1", row.CustomerID)
        cursor_dwh.execute("INSERT INTO Customer_Dim (CustomerID, CountryName, Start_Date, IsActive) VALUES (?, ?, GETDATE(), 1)", 
                           row.CustomerID, row.CountryName)

# ---------------------------------------------------------
# Schritt 4: Product_Dim (SCD Typ 2)
# ---------------------------------------------------------
print("ETL: Product_Dim (SCD 2)...")
cursor_oltp.execute("SELECT p.ProductID, p.StockCode, p.Description, c.CategoryName, p.CurrentPrice FROM Products p JOIN Categories c ON p.CategoryID = c.CategoryID")
for row in cursor_oltp.fetchall():
    cursor_dwh.execute("SELECT CurrentPrice FROM Product_Dim WHERE ProductID = ? AND IsActive = 1", row.ProductID)
    existing_prod = cursor_dwh.fetchone()

    if not existing_prod:
        cursor_dwh.execute("INSERT INTO Product_Dim (ProductID, StockCode, Description, CategoryName, CurrentPrice, Start_Date, IsActive) VALUES (?, ?, ?, ?, ?, GETDATE(), 1)", 
                           row.ProductID, row.StockCode, row.Description, row.CategoryName, row.CurrentPrice)
    elif float(existing_prod[0]) != float(row.CurrentPrice):
        cursor_dwh.execute("UPDATE Product_Dim SET IsActive = 0, End_Date = GETDATE() WHERE ProductID = ? AND IsActive = 1", row.ProductID)
        cursor_dwh.execute("INSERT INTO Product_Dim (ProductID, StockCode, Description, CategoryName, CurrentPrice, Start_Date, IsActive) VALUES (?, ?, ?, ?, ?, GETDATE(), 1)", 
                           row.ProductID, row.StockCode, row.Description, row.CategoryName, row.CurrentPrice)

# ---------------------------------------------------------
# Schritt 5: Time_Dim
# ---------------------------------------------------------
print("ETL: Time_Dim...")
cursor_oltp.execute("SELECT DISTINCT InvoiceDate FROM SalesHeaders")
for row in cursor_oltp.fetchall():
    dt = row.InvoiceDate
    full_date_str = dt.strftime('%Y-%m-%d')
    cursor_dwh.execute("""
        IF NOT EXISTS (SELECT 1 FROM Time_Dim WHERE FullDate = ?)
        INSERT INTO Time_Dim (FullDate, Year, Month, Day, Hour, Quarter, Week, Weekday)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)""", 
        full_date_str, full_date_str, dt.year, dt.month, dt.day, dt.hour, (dt.month - 1) // 3 + 1, dt.isocalendar()[1], dt.strftime('%A'))

conn_dwh.commit()

# ---------------------------------------------------------
# Schritt 6: Sales_Fact
# ---------------------------------------------------------
print("ETL: Sales_Fact Start...")
cursor_oltp.execute("""
    SELECT sh.CustomerID, sh.StoreID, sh.EmployeeID, sh.InvoiceDate, sd.ProductID, sd.Quantity, sd.UnitPrice
    FROM SalesHeaders sh JOIN SalesDetails sd ON sh.InvoiceNo = sd.InvoiceNo""")
fact_data = cursor_oltp.fetchall()

inserted_count = 0
for row in fact_data:
    try:
        t_search = row.InvoiceDate.strftime('%Y-%m-%d')
        # Surrogate Key Lookup mit IsActive-Prüfung für SCD2
        p_id = cursor_dwh.execute("SELECT Product_Dim_ID FROM Product_Dim WHERE ProductID = ? AND IsActive = 1", row.ProductID).fetchone()
        c_id = cursor_dwh.execute("SELECT Customer_Dim_ID FROM Customer_Dim WHERE CustomerID = ? AND IsActive = 1", row.CustomerID).fetchone()
        s_id = cursor_dwh.execute("SELECT Store_Dim_ID FROM Store_Dim WHERE StoreID = ?", row.StoreID).fetchone()
        e_id = cursor_dwh.execute("SELECT Employee_Dim_ID FROM Employee_Dim WHERE EmployeeID = ?", row.EmployeeID).fetchone()
        t_id = cursor_dwh.execute("SELECT Time_Dim_ID FROM Time_Dim WHERE FullDate = ?", t_search).fetchone()

        if all([p_id, c_id, s_id, e_id, t_id]):
            cursor_dwh.execute("""
                INSERT INTO Sales_Fact (Product_Dim_ID, Customer_Dim_ID, Store_Dim_ID, Employee_Dim_ID, Time_Dim_ID, Quantity, UnitPrice)
                VALUES (?, ?, ?, ?, ?, ?, ?)""", 
                p_id[0], c_id[0], s_id[0], e_id[0], t_id[0], row.Quantity, row.UnitPrice)
            inserted_count += 1
    except Exception:
        continue

conn_dwh.commit()
print(f"ETL abgeschlossen! {inserted_count} Datensätze geladen.")

conn_oltp.close()
conn_dwh.close()
