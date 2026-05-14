import pandas as pd
import pyodbc
import random

# 1. Verbindungseinstellungen (mit r zur Vermeidung von SyntaxWarning)
conn_str = r"Driver={SQL Server};Server=RZPC-0-155\SQLEXPRESS;Database=Retail_OLTP;Trusted_Connection=yes;"

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("Verbindung zur Retail_OLTP erfolgreich!")
except Exception as e:
    print(f"Fehler bei der Verbindung: {e}")
    exit()

# 2. Daten laden
file_path = 'data.csv'
df = pd.read_csv(file_path, encoding='ISO-8859-1')

# 3. Kategorisierungslogik
def get_category(desc):
    if pd.isna(desc): return "Others"
    desc = str(desc).upper()
    if any(x in desc for x in ['LIGHT', 'CANDLE', 'LANTERN']): return 'Lighting'
    if any(x in desc for x in ['KITCHEN', 'MUG', 'PLATE', 'BOWL']): return 'Kitchenware'
    if any(x in desc for x in ['BAG', 'BOX', 'STORAGE']): return 'Storage & Bags'
    if any(x in desc for x in ['HEART', 'LOVE', 'GIFT']): return 'Gifts'
    return 'Home Decor'

df['CategoryName'] = df['Description'].apply(get_category)

# 4. Stammdaten: Countries & Categories
print("Lade Stammdaten (Countries & Categories)...")
unique_countries = df['Country'].unique()
for country in unique_countries:
    cursor.execute(
        "IF NOT EXISTS (SELECT 1 FROM Countries WHERE CountryName = ?) INSERT INTO Countries (CountryName) VALUES (?)",
        country, country)

unique_categories = df['CategoryName'].unique()
for cat in unique_categories:
    cursor.execute(
        "IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = ?) INSERT INTO Categories (CategoryName) VALUES (?)",
        cat, cat)
conn.commit()

# Mapping IDs für Categories & Countries
cursor.execute("SELECT CategoryName, CategoryID FROM Categories")
cat_map = dict(cursor.fetchall())
cursor.execute("SELECT CountryName, CountryID FROM Countries")
country_map = dict(cursor.fetchall())

# 5. Stammdaten: Products
print("Lade Produkte...")
unique_products = df[['StockCode', 'Description', 'CategoryName', 'UnitPrice']].drop_duplicates('StockCode')

for _, row in unique_products.iterrows():
    try:
        price = round(float(row['UnitPrice']), 2)
        if pd.isna(price): price = 0.0
    except:
        price = 0.0

    cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Products WHERE StockCode = ?)
        BEGIN
            INSERT INTO Products (StockCode, Description, CategoryID, CurrentPrice)
            VALUES (?, ?, ?, ?)
        END""",
                   str(row['StockCode']), str(row['StockCode']),
                   str(row['Description'])[:255] if pd.notna(row['Description']) else "No Description",
                   cat_map[row['CategoryName']], price)
conn.commit()

# 6. Stammdaten: Customers (sehr wichtig zur Vermeidung von Foreign-Key-Fehlern)
print("Lade Kunden (Customers)...")
df_customers = df.dropna(subset=['CustomerID']).drop_duplicates('CustomerID')

for _, row in df_customers.iterrows():
    c_id = int(row['CustomerID'])
    c_country = row['Country']
    country_id = country_map.get(c_country, list(country_map.values())[0])

    cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = ?)
        INSERT INTO Customers (CustomerID, CountryID)
        VALUES (?, ?)""",
                   c_id, c_id, country_id)
conn.commit()

# 7. Transaktionsdaten: Sales (Header & Details)
print("Lade Verkaufsdaten (5000 records)...")

cursor.execute("SELECT StockCode, ProductID FROM Products")
prod_map = dict(cursor.fetchall())
cursor.execute("SELECT StoreID FROM Stores")
store_ids = [r[0] for r in cursor.fetchall()]
cursor.execute("SELECT EmployeeID FROM Employees")
emp_ids = [r[0] for r in cursor.fetchall()]

# Bereinigung der Verkaufsdaten
df_sales = df.dropna(subset=['InvoiceNo', 'CustomerID']).copy()
df_sales['CustomerID'] = df_sales['CustomerID'].astype(int)

for _, row in df_sales.head(5000).iterrows():
    # 1. SalesHeaders
    # Korrektur der Parameteranzahl: 1 für WHERE und 5 für VALUES = insgesamt 6 Fragezeichen
    cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM SalesHeaders WHERE InvoiceNo = ?)
        INSERT INTO SalesHeaders (InvoiceNo, InvoiceDate, CustomerID, StoreID, EmployeeID)
        VALUES (?, ?, ?, ?, ?)""",
                   str(row['InvoiceNo']), str(row['InvoiceNo']), row['InvoiceDate'],
                   row['CustomerID'], random.choice(store_ids), random.choice(emp_ids))

    # 2. SalesDetails
    try:
        u_price = round(float(row['UnitPrice']), 2)
    except:
        u_price = 0.0

    p_id = prod_map.get(str(row['StockCode']))
    if p_id:
        cursor.execute("""
            INSERT INTO SalesDetails (InvoiceNo, ProductID, Quantity, UnitPrice)
            VALUES (?, ?, ?, ?)""",
                       str(row['InvoiceNo']), p_id, int(row['Quantity']), u_price)

conn.commit()
print("OLTP-Datenbank erfolgreich befüllt!")
conn.close()
