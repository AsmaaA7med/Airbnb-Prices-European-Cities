-- Step 4: Star schema (Galaxy / fact constellation) - SQL Server
-- Fact_Listing_Price      : original Kaggle data (grain = one listing, city, day type)
-- Fact_Scraped_Listing    : scraped Airbnb data  (grain = one scraped listing)
-- Dim_City is shared (conformed) between both facts.

IF DB_ID('AirbnbDW') IS NULL CREATE DATABASE AirbnbDW;
GO
USE AirbnbDW;
GO

DROP TABLE IF EXISTS Fact_Scraped_Listing;
DROP TABLE IF EXISTS Fact_Listing_Price;
DROP TABLE IF EXISTS Dim_Host;
DROP TABLE IF EXISTS Dim_RoomType;
DROP TABLE IF EXISTS Dim_DayType;
DROP TABLE IF EXISTS Dim_City;
GO

CREATE TABLE Dim_City (
    city_key   INT IDENTITY(1,1) PRIMARY KEY,
    city_name  NVARCHAR(50) NOT NULL UNIQUE,
    country    NVARCHAR(50) NULL
);

CREATE TABLE Dim_DayType (
    daytype_key INT IDENTITY(1,1) PRIMARY KEY,
    day_type    NVARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE Dim_RoomType (
    room_key     INT IDENTITY(1,1) PRIMARY KEY,
    room_type    NVARCHAR(30) NOT NULL,
    room_shared  BIT NOT NULL,
    room_private BIT NOT NULL,
    CONSTRAINT UQ_Dim_RoomType UNIQUE (room_type, room_shared, room_private)
);

CREATE TABLE Dim_Host (
    host_key     INT IDENTITY(1,1) PRIMARY KEY,
    is_superhost BIT NOT NULL,
    is_multi     BIT NOT NULL,
    is_biz       BIT NOT NULL,
    CONSTRAINT UQ_Dim_Host UNIQUE (is_superhost, is_multi, is_biz)
);

CREATE TABLE Fact_Listing_Price (
    listing_key        INT IDENTITY(1,1) PRIMARY KEY,
    city_key           INT NOT NULL REFERENCES Dim_City(city_key),
    daytype_key        INT NOT NULL REFERENCES Dim_DayType(daytype_key),
    room_key           INT NOT NULL REFERENCES Dim_RoomType(room_key),
    host_key           INT NOT NULL REFERENCES Dim_Host(host_key),
    price              DECIMAL(12,2),
    person_capacity    INT,
    bedrooms           INT,
    cleanliness_rating DECIMAL(5,1),
    guest_satisfaction DECIMAL(5,1),
    dist_center        DECIMAL(10,4),
    dist_metro         DECIMAL(10,4),
    attr_index         DECIMAL(12,4),
    attr_index_norm    DECIMAL(12,4),
    rest_index         DECIMAL(12,4),
    rest_index_norm    DECIMAL(12,4),
    lat                DECIMAL(9,6),
    lng                DECIMAL(9,6)
);

CREATE TABLE Fact_Scraped_Listing (
    scraped_key       INT IDENTITY(1,1) PRIMARY KEY,
    city_key          INT NOT NULL REFERENCES Dim_City(city_key),
    room_key          INT NOT NULL REFERENCES Dim_RoomType(room_key),
    host_key          INT NULL REFERENCES Dim_Host(host_key),
    property_name     NVARCHAR(300),
    price             DECIMAL(12,2),
    rating            DECIMAL(3,2) NULL,
    num_reviews       INT,
    is_superhost      BIT,
    is_guest_favorite BIT,
    property_url      NVARCHAR(500)
);

CREATE INDEX IX_FLP_city ON Fact_Listing_Price(city_key);
CREATE INDEX IX_FSL_city ON Fact_Scraped_Listing(city_key);
GO

-- Handy view for Power BI (optional)
CREATE OR ALTER VIEW vw_City_Comparison AS
SELECT c.city_name,
       AVG(f.price)              AS avg_price_original_2br,
       (SELECT AVG(s.price) FROM Fact_Scraped_Listing s WHERE s.city_key = c.city_key) AS avg_price_scraped_2br
FROM Dim_City c
JOIN Fact_Listing_Price f ON f.city_key = c.city_key AND f.bedrooms = 2
GROUP BY c.city_name, c.city_key;
GO
