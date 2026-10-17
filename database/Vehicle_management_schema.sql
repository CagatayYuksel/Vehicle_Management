/*
Araç & Filo Yönetimi - SQL Server şema oluşturma betiği
Veritabanı: Vehicle_management

KULLANIM:
1. SQL Server Management Studio (SSMS) -> New Query
2. Bu dosyanın tamamını açıp çalıştırın.
3. Betik veritabanı yoksa oluşturur ve 16 tabloyu dbo şemasında oluşturur.

UYARILAR:
- Bu betik tablo şemasını oluşturur; Excel verilerini içe aktarmaz.
- Mevcut tabloları silmez. Aynı adlı tablolar zaten varsa CREATE TABLE aşamasında hata alırsınız.
- dbo.Users yalnızca uygulama/iş kullanıcıları için örnek tablodur.
  Django giriş sistemi için önerilen yaklaşım Django'nun auth_user/auth_group vb. tablolarını
  Django migrations ile oluşturmaktır. Bu Users tablosunu Django'nun auth tablosu sanmayın.
- TrafficFines.driver_id, RentalContractDrivers.id alanına bağlanır.
- Tutar alanlarında DECIMAL kullanılmıştır; kimlik alanları IDENTITY(1,1) biçimindedir.
*/

IF DB_ID(N'Vehicle_management') IS NULL
BEGIN
    CREATE DATABASE [Vehicle_management];
END;
GO

USE [Vehicle_management];
GO

/* 1. VehicleBrands */
CREATE TABLE dbo.VehicleBrands (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VehicleBrands PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    country NVARCHAR(100) NULL,
    logo NVARCHAR(500) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_VehicleBrands_is_active DEFAULT (1),
    CONSTRAINT UQ_VehicleBrands_name UNIQUE (name)
);
GO

/* 2. VehicleCategories */
CREATE TABLE dbo.VehicleCategories (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VehicleCategories PRIMARY KEY,
    name NVARCHAR(80) NOT NULL,
    description NVARCHAR(500) NULL,
    sort_order INT NOT NULL CONSTRAINT DF_VehicleCategories_sort_order DEFAULT (0),
    is_active BIT NOT NULL CONSTRAINT DF_VehicleCategories_is_active DEFAULT (1),
    CONSTRAINT UQ_VehicleCategories_name UNIQUE (name)
);
GO

/* 3. Locations */
CREATE TABLE dbo.Locations (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Locations PRIMARY KEY,
    name NVARCHAR(150) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    address NVARCHAR(500) NOT NULL,
    phone NVARCHAR(30) NULL,
    latitude DECIMAL(9,6) NULL,
    longitude DECIMAL(9,6) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_Locations_is_active DEFAULT (1),
    CONSTRAINT CK_Locations_latitude CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_Locations_longitude CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);
GO

/* 4. Customers */
CREATE TABLE dbo.Customers (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
    customer_type NVARCHAR(20) NOT NULL,
    first_name NVARCHAR(100) NULL,
    last_name NVARCHAR(100) NULL,
    company_name NVARCHAR(200) NULL,
    tax_number NVARCHAR(20) NULL,
    phone NVARCHAR(30) NOT NULL,
    email NVARCHAR(254) NULL,
    status NVARCHAR(20) NOT NULL CONSTRAINT DF_Customers_status DEFAULT (N'ACTIVE'),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Customers_type CHECK (customer_type IN (N'INDIVIDUAL', N'CORPORATE')),
    CONSTRAINT CK_Customers_name CHECK (
        (customer_type = N'INDIVIDUAL' AND first_name IS NOT NULL AND last_name IS NOT NULL)
        OR (customer_type = N'CORPORATE' AND company_name IS NOT NULL)
    )
);
GO

/* 5. MaintenanceTypes */
CREATE TABLE dbo.MaintenanceTypes (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MaintenanceTypes PRIMARY KEY,
    name NVARCHAR(120) NOT NULL,
    description NVARCHAR(500) NULL,
    default_interval_km INT NULL,
    default_interval_months INT NULL,
    is_active BIT NOT NULL CONSTRAINT DF_MaintenanceTypes_is_active DEFAULT (1),
    CONSTRAINT UQ_MaintenanceTypes_name UNIQUE (name),
    CONSTRAINT CK_MaintenanceTypes_interval_km CHECK (default_interval_km IS NULL OR default_interval_km > 0),
    CONSTRAINT CK_MaintenanceTypes_interval_months CHECK (default_interval_months IS NULL OR default_interval_months > 0)
);
GO

/* 6. VehicleModels */
CREATE TABLE dbo.VehicleModels (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VehicleModels PRIMARY KEY,
    brand_id INT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    generation NVARCHAR(50) NULL,
    segment NVARCHAR(30) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_VehicleModels_is_active DEFAULT (1),
    CONSTRAINT FK_VehicleModels_VehicleBrands FOREIGN KEY (brand_id)
        REFERENCES dbo.VehicleBrands(id),
    CONSTRAINT UQ_VehicleModels_brand_name_generation UNIQUE (brand_id, name, generation)
);
GO

/* 7. CustomerAddresses */
CREATE TABLE dbo.CustomerAddresses (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CustomerAddresses PRIMARY KEY,
    customer_id INT NOT NULL,
    address_type NVARCHAR(30) NOT NULL,
    country NVARCHAR(100) NOT NULL CONSTRAINT DF_CustomerAddresses_country DEFAULT (N'Türkiye'),
    city NVARCHAR(100) NOT NULL,
    district NVARCHAR(100) NULL,
    address_line NVARCHAR(500) NOT NULL,
    postal_code NVARCHAR(15) NULL,
    is_default BIT NOT NULL CONSTRAINT DF_CustomerAddresses_is_default DEFAULT (0),
    CONSTRAINT FK_CustomerAddresses_Customers FOREIGN KEY (customer_id)
        REFERENCES dbo.Customers(id) ON DELETE CASCADE
);
GO

/* 8. Vehicles */
CREATE TABLE dbo.Vehicles (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Vehicles PRIMARY KEY,
    plate NVARCHAR(15) NOT NULL,
    model_id INT NOT NULL,
    category_id INT NULL,
    model_year SMALLINT NOT NULL,
    color NVARCHAR(40) NULL,
    vin NVARCHAR(30) NULL,
    engine_number NVARCHAR(50) NULL,
    fuel_type NVARCHAR(30) NOT NULL,
    transmission NVARCHAR(30) NOT NULL,
    current_km INT NOT NULL CONSTRAINT DF_Vehicles_current_km DEFAULT (0),
    purchase_date DATE NULL,
    purchase_price DECIMAL(14,2) NULL,
    daily_price DECIMAL(12,2) NOT NULL,
    status NVARCHAR(30) NOT NULL CONSTRAINT DF_Vehicles_status DEFAULT (N'AVAILABLE'),
    description NVARCHAR(1000) NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_Vehicles_created_at DEFAULT (SYSDATETIME()),
    updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_Vehicles_updated_at DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Vehicles_VehicleModels FOREIGN KEY (model_id) REFERENCES dbo.VehicleModels(id),
    CONSTRAINT FK_Vehicles_VehicleCategories FOREIGN KEY (category_id) REFERENCES dbo.VehicleCategories(id),
    CONSTRAINT UQ_Vehicles_plate UNIQUE (plate),
    CONSTRAINT UQ_Vehicles_vin UNIQUE (vin),
    CONSTRAINT CK_Vehicles_model_year CHECK (model_year BETWEEN 1950 AND 2100),
    CONSTRAINT CK_Vehicles_current_km CHECK (current_km >= 0),
    CONSTRAINT CK_Vehicles_daily_price CHECK (daily_price >= 0),
    CONSTRAINT CK_Vehicles_purchase_price CHECK (purchase_price IS NULL OR purchase_price >= 0)
);
GO

/* 9. Reservations */
CREATE TABLE dbo.Reservations (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Reservations PRIMARY KEY,
    reservation_number NVARCHAR(30) NOT NULL,
    customer_id INT NOT NULL,
    vehicle_category_id INT NOT NULL,
    vehicle_id INT NULL,
    pickup_location_id INT NULL,
    return_location_id INT NULL,
    pickup_at DATETIME2(0) NOT NULL,
    return_at DATETIME2(0) NOT NULL,
    estimated_total DECIMAL(12,2) NOT NULL CONSTRAINT DF_Reservations_estimated_total DEFAULT (0),
    status NVARCHAR(30) NOT NULL CONSTRAINT DF_Reservations_status DEFAULT (N'PENDING'),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_Reservations_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Reservations_Customers FOREIGN KEY (customer_id) REFERENCES dbo.Customers(id),
    CONSTRAINT FK_Reservations_VehicleCategories FOREIGN KEY (vehicle_category_id) REFERENCES dbo.VehicleCategories(id),
    CONSTRAINT FK_Reservations_Vehicles FOREIGN KEY (vehicle_id) REFERENCES dbo.Vehicles(id),
    CONSTRAINT FK_Reservations_PickupLocation FOREIGN KEY (pickup_location_id) REFERENCES dbo.Locations(id),
    CONSTRAINT FK_Reservations_ReturnLocation FOREIGN KEY (return_location_id) REFERENCES dbo.Locations(id),
    CONSTRAINT UQ_Reservations_reservation_number UNIQUE (reservation_number),
    CONSTRAINT CK_Reservations_dates CHECK (return_at > pickup_at),
    CONSTRAINT CK_Reservations_estimated_total CHECK (estimated_total >= 0)
);
GO

/* 10. RentalContracts */
CREATE TABLE dbo.RentalContracts (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RentalContracts PRIMARY KEY,
    contract_number NVARCHAR(30) NOT NULL,
    reservation_id INT NULL,
    vehicle_id INT NOT NULL,
    customer_id INT NOT NULL,
    start_at DATETIME2(0) NOT NULL,
    end_at DATETIME2(0) NOT NULL,
    actual_return_at DATETIME2(0) NULL,
    pickup_km INT NOT NULL,
    return_km INT NULL,
    daily_rate DECIMAL(12,2) NOT NULL,
    deposit_amount DECIMAL(12,2) NOT NULL CONSTRAINT DF_RentalContracts_deposit DEFAULT (0),
    total_amount DECIMAL(14,2) NOT NULL CONSTRAINT DF_RentalContracts_total DEFAULT (0),
    status NVARCHAR(30) NOT NULL CONSTRAINT DF_RentalContracts_status DEFAULT (N'ACTIVE'),
    signed_at DATETIME2(0) NULL,
    CONSTRAINT FK_RentalContracts_Reservations FOREIGN KEY (reservation_id) REFERENCES dbo.Reservations(id),
    CONSTRAINT FK_RentalContracts_Vehicles FOREIGN KEY (vehicle_id) REFERENCES dbo.Vehicles(id),
    CONSTRAINT FK_RentalContracts_Customers FOREIGN KEY (customer_id) REFERENCES dbo.Customers(id),
    CONSTRAINT UQ_RentalContracts_contract_number UNIQUE (contract_number),
    CONSTRAINT CK_RentalContracts_dates CHECK (end_at > start_at),
    CONSTRAINT CK_RentalContracts_km CHECK (pickup_km >= 0 AND (return_km IS NULL OR return_km >= pickup_km)),
    CONSTRAINT CK_RentalContracts_amounts CHECK (daily_rate >= 0 AND deposit_amount >= 0 AND total_amount >= 0)
);
GO

/* 11. RentalContractDrivers */
CREATE TABLE dbo.RentalContractDrivers (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RentalContractDrivers PRIMARY KEY,
    contract_id INT NOT NULL,
    customer_id INT NOT NULL,
    is_primary_driver BIT NOT NULL CONSTRAINT DF_RentalContractDrivers_primary DEFAULT (0),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_RentalContractDrivers_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_RentalContractDrivers_RentalContracts FOREIGN KEY (contract_id) REFERENCES dbo.RentalContracts(id) ON DELETE CASCADE,
    CONSTRAINT FK_RentalContractDrivers_Customers FOREIGN KEY (customer_id) REFERENCES dbo.Customers(id),
    CONSTRAINT UQ_RentalContractDrivers_contract_customer UNIQUE (contract_id, customer_id)
);
GO

/* 12. MaintenanceRecords */
CREATE TABLE dbo.MaintenanceRecords (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MaintenanceRecords PRIMARY KEY,
    vehicle_id INT NOT NULL,
    maintenance_type_id INT NOT NULL,
    maintenance_date DATE NOT NULL,
    km_at_service INT NOT NULL,
    description NVARCHAR(1000) NULL,
    labor_cost DECIMAL(12,2) NOT NULL CONSTRAINT DF_MaintenanceRecords_labor DEFAULT (0),
    parts_cost DECIMAL(12,2) NOT NULL CONSTRAINT DF_MaintenanceRecords_parts DEFAULT (0),
    total_cost DECIMAL(12,2) NOT NULL CONSTRAINT DF_MaintenanceRecords_total DEFAULT (0),
    next_maintenance_date DATE NULL,
    next_maintenance_km INT NULL,
    invoice_number NVARCHAR(50) NULL,
    CONSTRAINT FK_MaintenanceRecords_Vehicles FOREIGN KEY (vehicle_id) REFERENCES dbo.Vehicles(id),
    CONSTRAINT FK_MaintenanceRecords_MaintenanceTypes FOREIGN KEY (maintenance_type_id) REFERENCES dbo.MaintenanceTypes(id),
    CONSTRAINT CK_MaintenanceRecords_km CHECK (km_at_service >= 0 AND (next_maintenance_km IS NULL OR next_maintenance_km >= km_at_service)),
    CONSTRAINT CK_MaintenanceRecords_costs CHECK (labor_cost >= 0 AND parts_cost >= 0 AND total_cost >= 0)
);
GO

/* 13. TrafficFines
   driver_id -> RentalContractDrivers.id (driver link record), not Customers.id. */
CREATE TABLE dbo.TrafficFines (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TrafficFines PRIMARY KEY,
    vehicle_id INT NOT NULL,
    driver_id INT NULL,
    contract_id INT NULL,
    fine_number NVARCHAR(40) NULL,
    fine_date DATE NOT NULL,
    notification_date DATE NULL,
    fine_type NVARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_deadline DATE NULL,
    payment_status NVARCHAR(20) NOT NULL CONSTRAINT DF_TrafficFines_payment_status DEFAULT (N'UNPAID'),
    objection_status NVARCHAR(20) NOT NULL CONSTRAINT DF_TrafficFines_objection_status DEFAULT (N'NONE'),
    evidence_file NVARCHAR(500) NULL,
    notes NVARCHAR(1000) NULL,
    CONSTRAINT FK_TrafficFines_Vehicles FOREIGN KEY (vehicle_id) REFERENCES dbo.Vehicles(id),
    CONSTRAINT FK_TrafficFines_RentalContractDrivers FOREIGN KEY (driver_id) REFERENCES dbo.RentalContractDrivers(id),
    CONSTRAINT FK_TrafficFines_RentalContracts FOREIGN KEY (contract_id) REFERENCES dbo.RentalContracts(id),
    CONSTRAINT CK_TrafficFines_amount CHECK (amount >= 0)
);
GO

/* 14. FinePayments */
CREATE TABLE dbo.FinePayments (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FinePayments PRIMARY KEY,
    fine_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method NVARCHAR(30) NOT NULL,
    transaction_reference NVARCHAR(100) NULL,
    receipt_file NVARCHAR(500) NULL,
    notes NVARCHAR(500) NULL,
    CONSTRAINT FK_FinePayments_TrafficFines FOREIGN KEY (fine_id) REFERENCES dbo.TrafficFines(id),
    CONSTRAINT CK_FinePayments_amount CHECK (amount > 0)
);
GO

/* 15. VehicleExpenses
   supplier_id intentionally has no FK until a Suppliers table is added. */
CREATE TABLE dbo.VehicleExpenses (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VehicleExpenses PRIMARY KEY,
    vehicle_id INT NOT NULL,
    expense_type NVARCHAR(80) NOT NULL,
    expense_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency CHAR(3) NOT NULL CONSTRAINT DF_VehicleExpenses_currency DEFAULT ('TRY'),
    supplier_id INT NULL,
    invoice_number NVARCHAR(50) NULL,
    invoice_file NVARCHAR(500) NULL,
    description NVARCHAR(1000) NULL,
    CONSTRAINT FK_VehicleExpenses_Vehicles FOREIGN KEY (vehicle_id) REFERENCES dbo.Vehicles(id),
    CONSTRAINT CK_VehicleExpenses_amount CHECK (amount >= 0)
);
GO

/* 16. Users - optional business/operator table, not Django auth_user */
CREATE TABLE dbo.Users (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    username NVARCHAR(150) NOT NULL,
    email NVARCHAR(254) NOT NULL,
    password_hash NVARCHAR(255) NULL,
    first_name NVARCHAR(150) NULL,
    last_name NVARCHAR(150) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_Users_is_active DEFAULT (1),
    is_staff BIT NOT NULL CONSTRAINT DF_Users_is_staff DEFAULT (0),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_Users_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_Users_username UNIQUE (username),
    CONSTRAINT UQ_Users_email UNIQUE (email)
);
GO

/* Indexes for common FK/filter columns */
CREATE INDEX IX_VehicleModels_brand_id ON dbo.VehicleModels(brand_id);
CREATE INDEX IX_Vehicles_model_id ON dbo.Vehicles(model_id);
CREATE INDEX IX_Vehicles_category_id ON dbo.Vehicles(category_id);
CREATE INDEX IX_CustomerAddresses_customer_id ON dbo.CustomerAddresses(customer_id);
CREATE INDEX IX_Reservations_customer_id ON dbo.Reservations(customer_id);
CREATE INDEX IX_Reservations_vehicle_dates ON dbo.Reservations(vehicle_id, pickup_at, return_at);
CREATE INDEX IX_RentalContracts_vehicle_id ON dbo.RentalContracts(vehicle_id);
CREATE INDEX IX_RentalContracts_customer_id ON dbo.RentalContracts(customer_id);
CREATE INDEX IX_MaintenanceRecords_vehicle_date ON dbo.MaintenanceRecords(vehicle_id, maintenance_date);
CREATE INDEX IX_TrafficFines_vehicle_date ON dbo.TrafficFines(vehicle_id, fine_date);
CREATE INDEX IX_FinePayments_fine_id ON dbo.FinePayments(fine_id);
CREATE INDEX IX_VehicleExpenses_vehicle_date ON dbo.VehicleExpenses(vehicle_id, expense_date);
GO

/* Verify created tables */
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = N'dbo'
ORDER BY t.name;
GO
