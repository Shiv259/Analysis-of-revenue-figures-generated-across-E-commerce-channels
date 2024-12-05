-- Step 1: Clean and Standardize the Column Names in the Master Tables
-- Renaming listing codes across different platform tables to a unified column name
ALTER TABLE amazon_master ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE "amazon_master" SET "Listing_Code" = "ASIN";
select * from amazon_master am ;

ALTER TABLE flipkart_master ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE flipkart_master SET "Listing_Code" = "FSN";
select * from flipkart_master fm ;

ALTER TABLE nykaa_master ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE nykaa_master SET "Listing_Code" = "SKU";
select * from nykaa_master nm ;

ALTER TABLE big_basket_master ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE big_basket_master SET "Listing_Code" = "Source_SKU_ID";
select * from big_basket_master bbm ;

ALTER TABLE blinkit_master ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE blinkit_master SET "Listing_Code" = "Item_Id";
select * from blinkit_master bm ;

-- Step 2: Merge the Master Tables with SKU_Final_Master to Create the Listing Master Table

CREATE TABLE "Listing_Master" AS
SELECT
    "L"."Listing_Code",
    "L"."MAT_Code",
    "S"."SKU Name",
    "S"."Brand",
    "S"."Category",
    "S"."Product_MRP"
FROM
    (
        SELECT "Listing_Code", "MAT_Code_1" AS "MAT_Code" FROM "amazon_master"
        UNION ALL
        SELECT "Listing_Code", "MAT_Code_2" AS "MAT_Code" FROM "flipkart_master"
        UNION ALL
        SELECT "Listing_Code", "MAT_Code_3" AS "MAT_Code" FROM "nykaa_master"
        UNION ALL
        SELECT "Listing_Code", "MAT_Code_5" AS "MAT_Code" FROM "big_basket_master"
        UNION ALL
        SELECT "Listing_Code", "MAT_Code_6" AS "MAT_Code" FROM "blinkit_master"
    ) AS "L"
JOIN
    "sku_final_master" AS "S" ON "L"."MAT_Code" = "S"."MAT code"; -- Check here if "MAT_Code" exists in "sku_final_master"
select * from "Listing_Master";

-- Step 3: Clean and Standardize the Sales Data Columns
-- Renaming columns in sales tables to create a unified structure
ALTER TABLE "amazon_sales" ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE "amazon_sales" SET "Listing_Code" = "ASIN";

ALTER TABLE "flipkart_sales" ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE "flipkart_sales" SET "Listing_Code" = "Product Id";

ALTER TABLE "nykaa_sales" ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE "nykaa_sales" SET "Listing_Code" = "Sku";

ALTER TABLE "big_basket_sales" ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE "big_basket_sales" SET "Listing_Code" = "source_sku_id";

ALTER TABLE "blinkit_sales" ADD COLUMN "Listing_Code" VARCHAR(255);
UPDATE "blinkit_sales" SET "Listing_Code" = "id";


-- Step 4: Merge the Sales Data with the Listing Master Table
CREATE TABLE "Sales_Master" AS
SELECT
    "L"."Listing_Code",
    "L"."SKU Name",
    "L"."Brand",
    "L"."Category",
    "L"."Product_MRP",
    "S"."Quantity_Sold",
    "S"."Sales_Channel",
    "S"."Order_Date"
FROM
    (
        SELECT "Listing_Code", "Quantity_Sold", 'Amazon' AS "Sales_Channel", "Purchase-date" AS "Order_Date" FROM "amazon_sales"
        UNION ALL
        SELECT "Listing_Code", "Final Units Sold" AS "Quantity_Sold", 'Flipkart' AS "Sales_Channel", "Order Date" FROM "flipkart_sales"
        UNION ALL
        SELECT "Listing_Code", "Quantity" AS "Quantity_Sold", 'Nykaa' AS "Sales_Channel", "Final date" AS "Order_Date" FROM "nykaa_sales"
        UNION ALL
        SELECT "Listing_Code", "total_quantity" AS "Quantity_Sold", 'BigBasket' AS "Sales_Channel", "date_range" AS "Order_Date" FROM "big_basket_sales"
        UNION ALL
        SELECT "Listing_Code", "qty_sold" AS "Quantity_Sold", 'Blinkit' AS "Sales_Channel", "date" AS "Order_Date" FROM "blinkit_sales"
    ) AS "S"
JOIN
    "Listing_Master" "L" ON "S"."Listing_Code" = "L"."Listing_Code";
select * from blinkit_sales bs ;
select * from "Sales_Master";


-- Step 5: Create the Calendar Table

CREATE TABLE "Calendar" AS
SELECT DISTINCT 
    CAST("Order_Date" AS DATE) AS "Order_Date",
    EXTRACT(YEAR FROM CAST("Order_Date" AS DATE)) AS "Year",
    EXTRACT(MONTH FROM CAST("Order_Date" AS DATE)) AS "Month",
    EXTRACT(DAY FROM CAST("Order_Date" AS DATE)) AS "Day"
FROM 
    "Sales_Master";
select * from "Calendar";

-- Step 6: Create the Key Performance Indicators (KPIs)
-- MTD Sales (Month-To-Date Sales)

--Adding a new column 
ALTER TABLE "Sales_Master"
ADD COLUMN "Standardized_Order_Date" DATE;

--Updating Standardized_Order_Date Column with Date Formats
UPDATE "Sales_Master"
SET "Standardized_Order_Date" = CASE
        -- If the date is in 'DD-MMM-YY' format (e.g., '15-Apr-24')
        WHEN "Order_Date" ~ '^\d{2}-[A-Za-z]{3}-\d{2}$' THEN TO_DATE("Order_Date", 'DD-Mon-YY')
        -- If the date is in 'DD-MM-YYYY' format (e.g., '17-07-2023')
        WHEN "Order_Date" ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE("Order_Date", 'DD-MM-YYYY')
        -- If the date is already in 'YYYY-MM-DD' format (e.g., '2024-03-03')
        WHEN "Order_Date" ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE("Order_Date", 'YYYY-MM-DD')
        -- Default case: if the date format does not match any of the above
        ELSE NULL
    END;

   select * from "Sales_Master";
 
--. Calculating Total Sales by Listing Code and Sales Channel
SELECT 
    "Listing_Code",
    "Sales_Channel",  
    SUM("Quantity_Sold") AS "Total_Quantity"
FROM 
    "Sales_Master"
GROUP BY 
    "Listing_Code", "Sales_Channel"
ORDER BY 
    "Listing_Code", "Sales_Channel";

   
    
select * from "Sales_Master";

--Monthly Sales Data
SELECT 
    EXTRACT(YEAR FROM "Standardized_Order_Date") AS "Year", 
    EXTRACT(MONTH FROM "Standardized_Order_Date") AS "Month", 
    SUM("Quantity_Sold" * "Product_MRP") AS "Total_Sales"
FROM 
    "Sales_Master"
WHERE 
    "Standardized_Order_Date" IS NOT NULL
GROUP BY 
    EXTRACT(YEAR FROM "Standardized_Order_Date"), 
    EXTRACT(MONTH FROM "Standardized_Order_Date")
ORDER BY 
    "Year" DESC, "Month" DESC;


-- Last Year Same Month Sales
   
   SELECT 
    EXTRACT(MONTH FROM "Standardized_Order_Date") AS "Month", 
    EXTRACT(YEAR FROM "Standardized_Order_Date") AS "Year", 
    SUM("Quantity_Sold" * "Product_MRP") AS "Last_Year_Same_Month_Sales"
FROM 
    "Sales_Master"
WHERE 
    "Standardized_Order_Date" >= CURRENT_DATE - INTERVAL '1 YEAR'  -- Filter data from the last year
    AND EXTRACT(MONTH FROM "Standardized_Order_Date") = EXTRACT(MONTH FROM CURRENT_DATE)  -- Same month as current date
GROUP BY 
    EXTRACT(MONTH FROM "Standardized_Order_Date"), 
    EXTRACT(YEAR FROM "Standardized_Order_Date")
ORDER BY 
    "Year" DESC, "Month" DESC;
   
   
--Total Sales by Year   
SELECT 
    EXTRACT(YEAR FROM "Standardized_Order_Date") AS "Year", 
    SUM("Quantity_Sold" * "Product_MRP") AS "Total_Sales"
FROM 
    "Sales_Master"
WHERE 
    "Standardized_Order_Date" IS NOT NULL
GROUP BY 
    EXTRACT(YEAR FROM "Standardized_Order_Date")
ORDER BY 
    "Year" DESC;

   
--   . Sales by Half-Year (H1/H2)
SELECT 
    CASE 
        WHEN EXTRACT(MONTH FROM "Standardized_Order_Date") IN (1, 2, 3, 4, 5, 6) THEN EXTRACT(YEAR FROM "Standardized_Order_Date") || '-H1'
        WHEN EXTRACT(MONTH FROM "Standardized_Order_Date") IN (7, 8, 9, 10, 11, 12) THEN EXTRACT(YEAR FROM "Standardized_Order_Date") || '-H2'
    END AS "Half_Year_Period",
    SUM("Quantity_Sold" * "Product_MRP") AS "Total_Sales"
FROM 
    "Sales_Master"
WHERE 
    "Standardized_Order_Date" IS NOT NULL
    AND "Standardized_Order_Date" >= CURRENT_DATE - INTERVAL '2 YEAR'
GROUP BY 
    "Half_Year_Period"
ORDER BY 
    "Half_Year_Period" DESC;
   
--   Quarterly Sales by Year
   SELECT 
    EXTRACT(YEAR FROM "Standardized_Order_Date") AS "Year",
    EXTRACT(QUARTER FROM "Standardized_Order_Date") AS "Quarter",
    SUM("Quantity_Sold" * "Product_MRP") AS "Quarterly_Sales"
FROM 
    "Sales_Master"
GROUP BY 
    EXTRACT(YEAR FROM "Standardized_Order_Date"),
    EXTRACT(QUARTER FROM "Standardized_Order_Date")
ORDER BY 
    "Year" DESC, "Quarter" DESC;

--   Total Revenue by Sales Channel
   SELECT 
    "Sales_Channel", 
    SUM("Quantity_Sold" * "Product_MRP") AS "Total_Revenue"
FROM 
    "Sales_Master"
GROUP BY 
    "Sales_Channel"
ORDER BY 
    "Total_Revenue" DESC;
   
   
--   Total Orders by Sales Channel and Quarter
SELECT 
    EXTRACT(YEAR FROM "Standardized_Order_Date") AS "Year", 
    EXTRACT(QUARTER FROM "Standardized_Order_Date") AS "Quarter", 
    "Sales_Channel",
    COUNT(DISTINCT "Listing_Code") AS "Total_Orders"
FROM 
    "Sales_Master"
GROUP BY 
    EXTRACT(YEAR FROM "Standardized_Order_Date"),
    EXTRACT(QUARTER FROM "Standardized_Order_Date"),
    "Sales_Channel"
ORDER BY 
    "Year" DESC, 
    "Quarter" DESC,
    "Sales_Channel";

   
--   Revenue Per Order by Listing Code
   SELECT 
    "Listing_Code",  -- Assuming there's an Order_ID to uniquely identify each order
    SUM("Quantity_Sold" * "Product_MRP") AS "Revenue_Per_Order"
FROM 
    "Sales_Master"
GROUP BY 
    "Listing_Code"
ORDER BY 
    "Revenue_Per_Order" DESC;
   
   

--   Most Sales in a month every year
   WITH Monthly_Sales AS (
    SELECT 
        EXTRACT(YEAR FROM "Standardized_Order_Date") AS "Year",
        EXTRACT(MONTH FROM "Standardized_Order_Date") AS "Month",
        SUM("Quantity_Sold" * "Product_MRP") AS "Total_Sales"
    FROM 
        "Sales_Master"
    GROUP BY 
        EXTRACT(YEAR FROM "Standardized_Order_Date"),
        EXTRACT(MONTH FROM "Standardized_Order_Date")
)
SELECT 
    "Year", 
    "Month", 
    "Total_Sales"
FROM 
    Monthly_Sales
WHERE 
    ("Year", "Total_Sales") IN (
        SELECT 
            "Year", 
            MAX("Total_Sales")
        FROM 
            Monthly_Sales
        GROUP BY 
            "Year"
    )
ORDER BY 
    "Year" DESC, "Month" DESC;



--Minimum Sales month every year
   WITH Monthly_Sales AS (
    SELECT 
        EXTRACT(YEAR FROM "Standardized_Order_Date") AS "Year",
        EXTRACT(MONTH FROM "Standardized_Order_Date") AS "Month",
        SUM("Quantity_Sold" * "Product_MRP") AS "Total_Sales"
    FROM 
        "Sales_Master"
    GROUP BY 
        EXTRACT(YEAR FROM "Standardized_Order_Date"),
        EXTRACT(MONTH FROM "Standardized_Order_Date")
)
SELECT 
    "Year", 
    "Month", 
    "Total_Sales"
FROM 
    Monthly_Sales
WHERE 
    ("Year", "Total_Sales") IN (
        SELECT 
            "Year", 
            MIN("Total_Sales")
        FROM 
            Monthly_Sales
        GROUP BY 
            "Year"
    )
ORDER BY 
    "Year" DESC, "Month" DESC;