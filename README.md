# Retail Data Warehouse & End-to-End BI Solution

Select Language: [English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>
## English: Project Documentation

### Project Scope
This project implements a complete data pipeline, migrating transactional records from an operational system into a Star Schema Data Warehouse. The solution focuses on data consistency, historical tracking via SCD Type 2, and advanced analytical reporting using SQL Server and Python.

### Technical Stack
* **Database:** SQL Server (OLTP & DWH)
* **ETL Engine:** Python (Pandas, PyODBC)
* **Key Features:** SCD Type 2 implementation, Persisted Computed Columns, and Keyword-based Categorization.

### Repository Structure
* `sql_scripts/`: SQL definitions for schemas and business intelligence queries.
* `python_etl/`: ETL logic for data migration and DWH transformation.
* `documentation/`: ER diagrams, Star Schema models, and the Product Mapping logic.

### Step-by-Step Execution Guide

#### 1. SQL Schema Initialization
* Execute `sql_scripts/01_create_oltp_schema.sql` to initialize the operational database and load base master data.
* Execute `sql_scripts/02_create_dwh_schema.sql` to deploy the Star Schema structure.

#### 2. Configuration
* Required libraries: `pip install pandas pyodbc`.
* Update the `server` connection string in the Python scripts to match the local SQL Server instance name.

#### 3. Data Processing (ETL)
* Run `python_etl/01_csv_to_oltp.py`: Cleans the source data and populates the OLTP system.
* Run `python_etl/02_oltp_to_dwh.py`: Transforms data, applies SCD logic, and populates the Fact table.

#### 4. Analytics & Reporting
* Use `sql_scripts/04_analytical_queries.sql` in SSMS to generate reports on RFM Segmentation, Peak Sales Hours, and Regional Performance.

---

<a name="deutsch"></a>
## Deutsch: Projektdokumentation

### Projektumfang
Implementierung einer vollständigen Daten-Pipeline zur Überführung transaktionaler Daten in ein Star Schema Data Warehouse. Der Fokus liegt auf Datenkonsistenz, Historisierung mittels SCD Typ 2 und Business-Reporting unter Einsatz von SQL Server und Python.

### Technologie-Stack
* **Datenbank:** SQL Server (OLTP & DWH)
* **ETL-Engine:** Python (Pandas, PyODBC)
* **Highlights:** SCD Typ 2 Implementierung, Persisted Computed Columns und Keyword-basiertes Mapping.

### Verzeichnisstruktur
* `sql_scripts/`: SQL-Skripte für Datenbank-Schemata und BI-Abfragen.
* `python_etl/`: ETL-Skripte für den Datentransfer und die DWH-Transformation.
* `documentation/`: ER-Diagramme, Star-Schema-Modelle und die Excel-Mapping-Tabelle.

### Schritt-für-Schritt-Anleitung zur Ausführung

#### Schritt 1: Datenbank-Initialisierung
* Führen Sie `sql_scripts/01_create_oltp_schema.sql` aus, um die operative Datenbank und die Stammdaten zu erstellen.
* Führen Sie `sql_scripts/02_create_dwh_schema.sql` aus, um die Data Warehouse-Struktur (Sternschema) bereitzustellen.

#### Schritt 2: Konfiguration
* Benötigte Bibliotheken: `pip install pandas pyodbc`.
* Passen Sie den Servernamen in den Python-Skripten an Ihre lokale SQL-Server-Instanz an.

#### Schritt 3: ETL-Durchführung
* Starten Sie `python_etl/01_csv_to_oltp.py`: Bereinigt die Quelldaten und befüllt das OLTP-System.
* Starten Sie `python_etl/02_oltp_to_dwh.py`: Transformiert die Daten, wendet die SCD-Logik an und lädt die Faktentabelle.

#### Schritt 4: Analyse & Reporting
* Nutzen Sie `sql_scripts/04_analytical_queries.sql` im SSMS für Berichte wie RFM-Segmentierung, Peak-Sales-Analysen und regionale Performance-Rankings.

---

### Prerequisites / Voraussetzungen
* Microsoft SQL Server & SSMS
* Python 3.x
* Online Retail Dataset (Kaggle)
