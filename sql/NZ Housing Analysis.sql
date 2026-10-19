CREATE DATABASE NZ_COST_OF_LIVING;
USE NZ_COST_OF_LIVING;

CREATE TABLE CPI_Inflation (
    Category VARCHAR(100),
    Code VARCHAR(20),
    Level1 VARCHAR(20),
    Quarter VARCHAR(20),
    Inflation DECIMAL(5,2)
);
LOAD DATA LOCAL INFILE 'C:/Users/msiva/OneDrive/Documents/NZ Housing Affordability/CPI_Inflation.csv'
INTO TABLE CPI_Inflation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Category, Code, Level1, Quarter, Inflation);


CREATE TABLE CPI_Index (
    Category VARCHAR(100),
    Code VARCHAR(20),
    Level1 VARCHAR(20),
    Quarter VARCHAR(20),
    CPI_Index INT
);

LOAD DATA LOCAL INFILE 'C:/Users/msiva/OneDrive/Documents/NZ Housing Affordability/CPI_Index.csv'
INTO TABLE CPI_Index
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Category, Code, Level1, Quarter, CPI_Index);


CREATE TABLE CPI_Regional (
    Category VARCHAR(100),
    Region TEXT,
    Quarter VARCHAR(20),
    Inflation DECIMAL(5,2)
);

LOAD DATA LOCAL INFILE 'C:/Users/msiva/OneDrive/Documents/NZ Housing Affordability/CPI_Regional.csv'
INTO TABLE CPI_Regional
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(Category, Region, Quarter, Inflation);


CREATE TABLE CPI_RetailPrices (
    Item TEXT,
    Code VARCHAR(20),
    Unit VARCHAR(20),
    Quarter VARCHAR(20),
    Retail_Price DECIMAL(5,2)
);

LOAD DATA LOCAL INFILE 'C:/Users/msiva/OneDrive/Documents/NZ Housing Affordability/CPI_RetailPrices.csv'
INTO TABLE CPI_RetailPrices
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(Item, Code, Unit, Quarter, Retail_Price);


CREATE TABLE CPI_Weights (
    Category TEXT,
    Code VARCHAR(20),
    Weight_December_2024_quarter DECIMAL(5,2)
);

LOAD DATA LOCAL INFILE 'C:/Users/msiva/OneDrive/Documents/NZ Housing Affordability/CPI_Weights.csv'
INTO TABLE CPI_Weights
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(Category, Code, Weight_December_2024_quarter);


DROP TABLE Retail_Category_Mapping;
CREATE TABLE Retail_Category_Mapping (
Retail_Item TEXT,
Retail_Code VARCHAR (20),
CPI_Category_Code VARCHAR (20));

LOAD DATA LOCAL INFILE 'C:/Users/msiva/OneDrive/Documents/NZ Housing Affordability/Retail_Category_Mapping_Cleaned.csv'
INTO TABLE Retail_Category_Mapping
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(Retail_Item, Retail_Code, CPI_Category_Code);



##1 — Overall Inflation Trend;

## 1 — Overall Inflation Trend

SELECT * FROM CPI_Inflation;
SELECT Category, Code, Level1, Quarter, Inflation from CPI_Inflation
WHERE Code = 'SE9A' AND  Level1 = "Overall" ORDER BY  STR_TO_DATE(Quarter, '%b-%y') ;

## 2.Which CPI categories had the highest inflation in each quarter?



SELECT Category, Quarter, Inflation
FROM CPI_Inflation
WHERE Level1 = 'Group'
AND (Quarter, Inflation) IN (
    SELECT Quarter, MAX(Inflation)
    FROM CPI_Inflation
    WHERE Level1 = 'Group'
    GROUP BY Quarter
)
ORDER BY STR_TO_DATE(Quarter, '%b-%y');


## 3 Which CPI categories had the biggest increase in inflation from Jun-25 to Jun-26?

SELECT * FROM CPI_Inflation;
SELECT
    Category,
    MAX(IF(Quarter = 'Jun-25', Inflation, NULL)) AS Jun_25,
    MAX(IF(Quarter = 'Jun-26', Inflation, NULL)) AS Jun_26,
    MAX(IF(Quarter = 'Jun-26', Inflation, NULL))
      - MAX(IF(Quarter = 'Jun-25', Inflation, NULL)) AS Inflation_Change
FROM CPI_Inflation
WHERE Level1 = 'Group'
GROUP BY Category
ORDER BY Inflation_Change DESC
LIMIT 1;

## 4 Which CPI categories had the highest and lowest inflation overall?

SELECT * FROM CPI_Inflation;
SELECT Category, AVG(Inflation) AS Category_Avg
FROM CPI_Inflation WHERE Level1 = 'Group' GROUP BY Category
ORDER BY Category_Avg DESC LIMIT 3;

SELECT Category, AVG(Inflation) AS Category_Avg
FROM CPI_Inflation WHERE Level1 = 'Group' GROUP BY Category
ORDER BY Category_Avg ASC LIMIT 3;

## 5 Which regions had the highest and lowest overall inflation?

SELECT Region, AVG(Inflation) AS Region_Avg
FROM CPI_Regional WHERE Category = "All groups" GROUP BY Region ORDER BY Region_Avg DESC LIMIT 3;

SELECT Region, AVG(Inflation) AS Region_Avg
FROM CPI_Regional WHERE Category = "All groups" GROUP BY Region ORDER BY Region_Avg ASC LIMIT 3;

## 6 Which regions had the highest and lowest Housing & household utilities inflation?

SELECT Region, AVG(Inflation) AS Region_Avg
FROM CPI_Regional WHERE Category = "Housing and household utilities " GROUP BY Region ORDER BY Region_Avg DESC LIMIT 3;

SELECT Region, AVG(Inflation) AS Region_Avg
FROM CPI_Regional WHERE Category = "Housing and household utilities " GROUP BY Region ORDER BY Region_Avg ASC LIMIT 3;

## 7 Which retail items had the biggest price increase from Jun-25 to Jun-26?

SELECT Item,
MAX(IF(Quarter = 'Jun-25', Retail_Price, NULL)) AS Jun_25_Price,
MAX(IF(Quarter = 'Jun-26', Retail_Price, NULL)) AS Jun_26_Price,
MAX(IF(Quarter = 'Jun-26', Retail_Price, NULL))
- MAX(IF(Quarter = 'Jun-25', Retail_Price, NULL)) AS Price_Change
FROM CPI_RetailPrices
WHERE Quarter IN ('Jun-25', 'Jun-26')
GROUP BY Item ORDER BY Price_Change DESC LIMIT 5;


## 8 Which CPI categories create the greatest household cost pressure?


SELECT CPI_Inflation.Category, CPI_Inflation.Inflation, CPI_Weights.Weight_December_2024_quarter, 
CPI_Inflation.Inflation*CPI_Weights.Weight_December_2024_quarter/100 AS Cost_Pressure
FROM CPI_Inflation JOIN CPI_Weights
ON CPI_Inflation.Code = CPI_Weights.Code
WHERE Level1 = "Group" AND Quarter = "Jun-26" ORDER BY Cost_Pressure DESC;

## 9 Which CPI categories have high inflation, high expenditure weight, and rising retail prices?

SELECT 
    CPI_Inflation.Category,
    CPI_Inflation.Inflation,
    CPI_Weights.Weight_December_2024_quarter AS Weight,
    CPI_RetailPrices.Item,

    MAX(IF(CPI_RetailPrices.Quarter = 'Jun-25', 
        CPI_RetailPrices.Retail_Price, NULL)) AS Jun_25_Price,

    MAX(IF(CPI_RetailPrices.Quarter = 'Jun-26', 
        CPI_RetailPrices.Retail_Price, NULL)) AS Jun_26_Price,

    MAX(IF(CPI_RetailPrices.Quarter = 'Jun-26', 
        CPI_RetailPrices.Retail_Price, NULL))
    -
    MAX(IF(CPI_RetailPrices.Quarter = 'Jun-25', 
        CPI_RetailPrices.Retail_Price, NULL)) AS Price_Change

FROM CPI_Inflation 
JOIN CPI_Weights
    ON CPI_Inflation.Code = CPI_Weights.Code

JOIN Retail_Category_Mapping
    ON CPI_Inflation.Code = Retail_Category_Mapping.CPI_Category_Code

JOIN CPI_RetailPrices
    ON Retail_Category_Mapping.Retail_Code = CPI_RetailPrices.Code

WHERE CPI_Inflation.Level1 = 'Group'
AND CPI_Inflation.Quarter = 'Jun-26'
AND CPI_RetailPrices.Quarter IN ('Jun-25', 'Jun-26')

GROUP BY 
    CPI_Inflation.Category,
    CPI_Inflation.Inflation,
    CPI_Weights.Weight_December_2024_quarter,
    CPI_RetailPrices.Item

ORDER BY Price_Change DESC;


## 10 Which CPI categories experienced rising inflation and CPI index while also having a large household expenditure weight?

SELECT CPI_Inflation.Category, CPI_Inflation.Code, CPI_Weights.Weight_December_2024_quarter,
MAX(IF(CPI_Inflation.Quarter = 'Jun-25', CPI_Inflation.Inflation, NULL)) AS Jun_25_Inflation,
MAX(IF(CPI_Inflation.Quarter = 'Jun-26', CPI_Inflation.Inflation, NULL)) AS Jun_26_Inflation,
MAX(IF(CPI_Inflation.Quarter = 'Jun-26', CPI_Inflation.Inflation, NULL)) - 
MAX(IF(CPI_Inflation.Quarter = 'Jun-25', CPI_Inflation.Inflation, NULL)) AS Inflation_Change ,
MAX(IF(CPI_Index.Quarter = 'Jun-25', CPI_Index.CPI_Index, NULL)) AS Jun_25_CPI_Index,
MAX(IF(CPI_Index.Quarter = 'Jun-26', CPI_Index.CPI_Index, NULL)) AS Jun_26_CPI_Index,
MAX(IF(CPI_Index.Quarter = 'Jun-26', CPI_Index.CPI_Index, NULL)) - 
MAX(IF(CPI_Index.Quarter = 'Jun-25', CPI_Index.CPI_Index, NULL)) AS CPI_Index_Change
FROM CPI_Inflation JOIN CPI_Index ON CPI_Inflation.Code = CPI_Index.Code 
AND CPI_Inflation.Quarter = CPI_Index.Quarter
JOIN CPI_Weights ON CPI_Inflation.Code = CPI_Weights.Code
WHERE CPI_Inflation.Level1 = "Group" AND CPI_Inflation.Quarter IN ("Jun-25","Jun-26")
GROUP BY 
CPI_Inflation.Category,
CPI_Inflation.Code,
CPI_Weights.Weight_December_2024_quarter
HAVING Inflation_Change > 0 AND CPI_Index_Change > 0
ORDER BY Weight_December_2024_quarter DESC;


SELECT USER(), CURRENT_USER();