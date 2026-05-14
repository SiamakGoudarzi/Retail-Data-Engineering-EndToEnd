USE Retail_OLTP;
GO

INSERT INTO Countries (CountryName)
VALUES 
    ('Deutschland'),
    ('Vereinigtes Königreich'),
    ('Frankreich'),
    ('Spanien'),
    ('Italien');

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

INSERT INTO Employees (FullName, StoreID)
VALUES
    ('Anna Schmidt', 1),
    ('Jonas Weber', 1),
    ('Laura Klein', 2),
    ('Michael Braun', 2),
    ('Sophie Wagner', 3),
    ('Felix Hoffmann', 3),
    ('Lena Fischer', 4),
    ('David Richter', 4),
    ('Julia Vogel', 5),
    ('Thomas Keller', 5),
    ('Emily Johnson', 6),
    ('Oliver Smith', 6),
    ('Chloe Brown', 7),
    ('Jack Wilson', 7),
    ('Marie Dubois', 8),
    ('Pierre Martin', 8),
    ('Carlos Garcia', 9),
    ('Lucia Fernandez', 9),
    ('Marco Rossi', 10),
    ('Giulia Bianchi', 10);