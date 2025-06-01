CREATE DATABASE Propellant;

USE Propellant;

SELECT * FROM transformed_kerala_fuel_prices;

-- Checking null values
SELECT * FROM transformed_kerala_fuel_prices WHERE Date IS NULL AND District IS NULL AND
Fuel_Type IS NULL AND Price IS NULL;

-- Checking duplicated values
WITH duplicate_rows AS (
    SELECT Date, District, Fuel_Type, Price
    FROM transformed_kerala_fuel_prices
    GROUP BY Date, District, Fuel_Type, Price
    HAVING COUNT(*) > 1
)
SELECT *
FROM transformed_kerala_fuel_prices tfp
JOIN duplicate_rows dr
ON tfp.Date = dr.Date
   AND tfp.District = dr.District
   AND tfp.Fuel_Type = dr.Fuel_Type
   AND tfp.Price = dr.Price;
   
   
-- zscore

WITH stats AS (
  SELECT 
    Fuel_Type,
    AVG(Price) AS mean_price,
    STDDEV_POP(Price) AS std_dev
  FROM transformed_kerala_fuel_prices
  GROUP BY Fuel_Type
),
z_scores AS (
  SELECT 
    t.Date,
    t.District,
    t.Fuel_Type,
    t.Price,
    s.mean_price,
    s.std_dev,
    (t.Price - s.mean_price) / s.std_dev AS z_score
  FROM transformed_kerala_fuel_prices t
  JOIN stats s ON t.Fuel_Type = s.Fuel_Type
)
SELECT *
FROM z_scores
WHERE ABS(z_score) > 3
ORDER BY ABS(z_score) DESC;

   
-- Date format handling
CREATE OR REPLACE VIEW transformed_fuel_prices_view AS
SELECT 
    *,
    STR_TO_DATE(Date, '%d-%m-%Y') AS Converted_Date
FROM transformed_kerala_fuel_prices;

-- 1. Average price of petrol and diesel for each district
SELECT District, Fuel_Type, ROUND(AVG(Price), 2) AS Avg_Price
FROM transformed_kerala_fuel_prices
GROUP BY District, Fuel_Type
ORDER BY District, Fuel_Type;

-- 2. Top 1 district with the highest average fuel price for both Petrol and Diesel
WITH AvgPrices AS (
  SELECT 
    Fuel_Type,
    District,
    ROUND(AVG(Price), 2) AS Avg_Price,
    ROW_NUMBER() OVER (PARTITION BY Fuel_Type ORDER BY AVG(Price) DESC) AS rn
  FROM transformed_kerala_fuel_prices
  GROUP BY Fuel_Type, District
)
SELECT Fuel_Type, District, Avg_Price
FROM AvgPrices
WHERE rn = 1;

-- 3. Monthly average price trend for each fuel type across Kerala (with District)
SELECT 
  DATE_FORMAT(t.Converted_Date, '%Y-%m') AS Month,
  t.District,
  t.Fuel_Type,
  ROUND(AVG(t.Price_Change), 2) AS Avg_Monthly_Price
FROM (
  SELECT * FROM transformed_fuel_prices_view
) AS t
GROUP BY Month, t.District, t.Fuel_Type
ORDER BY Month, t.District, t.Fuel_Type;


ALTER TABLE transformed_kerala_fuel_prices 
RENAME COLUMN `Change` TO Price_Change;

SELECT * FROM transformed_kerala_fuel_prices;

--  4. Most volatile fuel prices (by average absolute daily change)
SELECT District, Fuel_Type, ROUND(AVG(ABS(Price_Change)), 3) AS Avg_Change
FROM transformed_kerala_fuel_prices
GROUP BY District, Fuel_Type
ORDER BY Avg_Change DESC;

-- 5.Dates with the largest price increase or decrease
SELECT *
FROM transformed_kerala_fuel_prices
ORDER BY ABS(Price_Change) DESC
LIMIT 5;

-- 6. Count of days with increase, decrease, or no change per district and fuel
SELECT 
  District,
  Fuel_Type,
  SUM(CASE WHEN Price_Change > 0 THEN 1 ELSE 0 END) AS Days_Increased,
  SUM(CASE WHEN Price_Change < 0 THEN 1 ELSE 0 END) AS Days_Decreased,
  SUM(CASE WHEN Price_Change = 0 THEN 1 ELSE 0 END) AS Days_No_Change
FROM transformed_kerala_fuel_prices
GROUP BY District, Fuel_Type;

-- 7. Cumulative price change by district and fuel type
SELECT 
  District,
  Fuel_Type,
  ROUND(SUM(Price_Change), 2) AS Total_Change
FROM transformed_kerala_fuel_prices
GROUP BY District, Fuel_Type
ORDER BY Total_Change DESC;

-- 8. District with most stable fuel prices (lowest std deviation)
SELECT District, Fuel_Type, ROUND(STDDEV(Price_Change), 3) AS Std_Dev
FROM transformed_kerala_fuel_prices
GROUP BY District, Fuel_Type
ORDER BY Std_Dev ASC
LIMIT 5;

-- 9. Top 5 districts with the highest cumulative petrol price increase (including fuel type)
SELECT 
  District, 
  Fuel_Type,
  ROUND(SUM(Price_Change), 2) AS Total_Increase
FROM transformed_kerala_fuel_prices
WHERE Fuel_Type = 'Petrol' AND Price_Change > 0
GROUP BY District, Fuel_Type
ORDER BY Total_Increase DESC
LIMIT 5;

-- 10. Monthly price change trend for a specific district (e.g., Ernakulam)
SELECT 
  District,
  DATE_FORMAT(Converted_Date, '%Y-%m') AS Month,
  Fuel_Type,
  ROUND(SUM(Price_Change), 2) AS Monthly_Change
FROM transformed_fuel_prices_view
WHERE District = 'Ernakulam'
GROUP BY District, Month, Fuel_Type
ORDER BY District, Month, Fuel_Type;

#-- 11. Days with no price change across all districts and fuel types
SELECT Date, COUNT(*) AS No_Change_Records
FROM transformed_kerala_fuel_prices
WHERE Price_Change = 0
GROUP BY Date
ORDER BY No_Change_Records DESC
LIMIT 5;


-- 12. Districts with continuous increase for more than 3 days (example for Petrol)
SELECT District, Date, Fuel_Type, Price_Change
FROM (
  SELECT *,
         LAG(Price_Change, 1) OVER (PARTITION BY District, Fuel_Type ORDER BY Converted_Date) AS Prev1,
         LAG(Price_Change, 2) OVER (PARTITION BY District, Fuel_Type ORDER BY Converted_Date) AS Prev2,
         LAG(Price_Change, 3) OVER (PARTITION BY District, Fuel_Type ORDER BY Converted_Date) AS Prev3
  FROM transformed_fuel_prices_view
  WHERE Fuel_Type IN ('Petrol', 'Diesel')
) AS sub
WHERE Price_Change > 0 AND Prev1 > 0 AND Prev2 > 0 AND Prev3 > 0
ORDER BY District, Fuel_Type, Date;

-- 13. Max consecutive days with no price change per district and fuel
-- Note: This requires a more complex approach with ROW_NUMBER or sessionized logic, not trivial in plain SQL.
-- A simplified version to show longest streaks:
WITH NoChange AS (
  SELECT 
    District,
    Fuel_Type,
    Date,
    ROW_NUMBER() OVER (PARTITION BY District, Fuel_Type ORDER BY Date) AS rn
  FROM transformed_kerala_fuel_prices
  WHERE Price_Change = 0
),
StreakGroups AS (
  SELECT 
    District,
    Fuel_Type,
    Date,
    DATE_SUB(Date, INTERVAL rn DAY) AS grp_date
  FROM NoChange
),
StreakCounts AS (
  SELECT 
    District,
    Fuel_Type,
    COUNT(*) AS streak_length,
    MIN(Date) AS streak_start,
    MAX(Date) AS streak_end
  FROM StreakGroups
  GROUP BY District, Fuel_Type, grp_date
)
SELECT 
  District,
  Fuel_Type,
  streak_length,
  streak_start,
  streak_end
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY District, Fuel_Type ORDER BY streak_length DESC) AS rnk
  FROM StreakCounts
) AS ranked
WHERE rnk = 1
ORDER BY streak_length DESC
LIMIT 5;


-- 14. Compare petrol and diesel average prices side-by-side for each district
SELECT 
  District,
  ROUND(AVG(CASE WHEN Fuel_Type = 'Petrol' THEN Price END), 2) AS Avg_Petrol,
  ROUND(AVG(CASE WHEN Fuel_Type = 'Diesel' THEN Price END), 2) AS Avg_Diesel
FROM transformed_kerala_fuel_prices
GROUP BY District
ORDER BY District;

-- 15. Overall Kerala average fuel price trend per month (both fuels combined)
SELECT 
  DATE_FORMAT(Converted_Date, '%Y-%m') AS Month,
  ROUND(AVG(Price), 2) AS Avg_Combined_Fuel_Price
FROM transformed_fuel_prices_view
GROUP BY Month
ORDER BY Month;

-- 16. Which fuel had more price volatility on average across Kerala?
SELECT Fuel_Type, ROUND(STDDEV(Price_Change), 3) AS Price_Change_Volatility
FROM transformed_kerala_fuel_prices
GROUP BY Fuel_Type
ORDER BY Price_Change_Volatility DESC;

-- 17. Total number of days prices were changed per district
SELECT District, COUNT(*) AS Price_Changed_Days
FROM transformed_kerala_fuel_prices
WHERE Price_Change != 0
GROUP BY District
ORDER BY Price_Changed_Days DESC;

-- 18. Price difference between petrol and diesel on the same date in each district
SELECT 
  a.District,
  a.Date,
  ROUND(a.Price - b.Price, 2) AS Petrol_Diesel_Diff
FROM transformed_kerala_fuel_prices a
JOIN transformed_kerala_fuel_prices b 
  ON a.District = b.District AND a.Date = b.Date
WHERE a.Fuel_Type = 'Petrol' AND b.Fuel_Type = 'Diesel'
ORDER BY ABS(a.Price - b.Price) DESC
LIMIT 10;

-- 19. Daily average price across Kerala for each fuel type
SELECT 
  Converted_Date AS Date,
  Fuel_Type,
  ROUND(AVG(Price), 2) AS Daily_Avg_Price
FROM transformed_fuel_prices_view
GROUP BY Converted_Date, Fuel_Type
ORDER BY Converted_Date, Fuel_Type;

-- 20. Detect sudden spikes or drops greater than ₹1 in a single day
SELECT *
FROM transformed_kerala_fuel_prices
WHERE ABS(Price_Change) > 1
ORDER BY ABS(Price_Change) DESC;

-- 21. Rolling 7-day average price for each district and fuel type
SELECT 
  District,
  Fuel_Type,
  Converted_Date AS Date,
  ROUND(AVG(Price) OVER (
    PARTITION BY District, Fuel_Type
    ORDER BY Converted_Date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2) AS Rolling_7Day_Avg
FROM transformed_fuel_prices_view
ORDER BY District, Fuel_Type, Date;

-- 22. Count of price hikes >= ₹0.5 per district and fuel
SELECT 
  District,
  Fuel_Type,
  COUNT(*) AS Count_Hikes
FROM transformed_kerala_fuel_prices
WHERE Price_Change >= 0.5
GROUP BY District, Fuel_Type
ORDER BY Count_Hikes DESC;

-- 23. Identify fuel types with more frequent price changes
SELECT 
  Fuel_Type,
  COUNT(*) AS Total_Changes
FROM transformed_kerala_fuel_prices
WHERE Price_Change != 0
GROUP BY Fuel_Type
ORDER BY Total_Changes DESC;

-- 24. Identify districts with most price changes (increase or decrease)
SELECT 
  District,
  COUNT(*) AS Total_Price_Changes
FROM transformed_kerala_fuel_prices
WHERE Price_Change != 0
GROUP BY District
ORDER BY Total_Price_Changes DESC;

-- 25. Price change trend before and after major events (e.g., 2024 election, pick a date)
SELECT 
  CASE 
    WHEN Converted_Date < '2024-05-01' THEN 'Before May 2024'
    ELSE 'After May 2024'
  END AS Period,
  Fuel_Type,
  ROUND(AVG(Price_Change), 3) AS Avg_Change
FROM transformed_fuel_prices_view
GROUP BY Period, Fuel_Type
ORDER BY Period, Fuel_Type;

-- 26. Which fuel type is more stable (lower average change magnitude)?
SELECT 
  Fuel_Type,
  ROUND(AVG(ABS(Price_Change)), 3) AS Avg_Abs_Change
FROM transformed_kerala_fuel_prices
GROUP BY Fuel_Type
ORDER BY Avg_Abs_Change ASC;

-- 27. Distribution of price change values (for histogram/binning)
SELECT 
  District,
  Fuel_Type,
  CASE 
    WHEN Price_Change <= -2 THEN '≤ -2'
    WHEN Price_Change > -2 AND Price_Change <= -1 THEN '-2 to -1'
    WHEN Price_Change > -1 AND Price_Change < 0 THEN '-1 to 0'
    WHEN Price_Change = 0 THEN '0'
    WHEN Price_Change > 0 AND Price_Change <= 1 THEN '0 to 1'
    WHEN Price_Change > 1 AND Price_Change <= 2 THEN '1 to 2'
    ELSE '> 2'
  END AS Change_Range,
  COUNT(*) AS Frequency
FROM transformed_kerala_fuel_prices
GROUP BY District, Fuel_Type, Change_Range
ORDER BY District, Fuel_Type, 
  FIELD(Change_Range, '≤ -2', '-2 to -1', '-1 to 0', '0', '0 to 1', '1 to 2', '> 2');


-- 28. Compare average monthly price change before and after implementation of daily pricing policy (if applicable)
SELECT 
  CASE 
    WHEN Converted_Date < '2024-12-31' THEN 'Before Daily Pricing'
    ELSE 'After Daily Pricing'
  END AS Pricing_Era,
  Fuel_Type,
  ROUND(AVG(ABS(Price_Change)), 3) AS Avg_Change
FROM transformed_fuel_prices_view
GROUP BY Pricing_Era, Fuel_Type
ORDER BY Pricing_Era, Fuel_Type;

-- 29. Compute summary stats for Petrol and Diesel per district
WITH stats AS (
  SELECT
    District,
    Fuel_Type,
    COUNT(*) AS n,
    AVG(Price_Change) AS mean_pc,
    VAR_SAMP(Price_Change) AS var_pc
  FROM transformed_kerala_fuel_prices
  GROUP BY District, Fuel_Type
),
pivot_stats AS (
  SELECT
    p.District,
    p.mean_pc AS mean_petrol,
    p.var_pc AS var_petrol,
    p.n AS n_petrol,
    d.mean_pc AS mean_diesel,
    d.var_pc AS var_diesel,
    d.n AS n_diesel
  FROM
    (SELECT * FROM stats WHERE Fuel_Type = 'Petrol') p
    JOIN
    (SELECT * FROM stats WHERE Fuel_Type = 'Diesel') d
    ON p.District = d.District
)
SELECT
  District,
  mean_petrol,
  mean_diesel,
  var_petrol,
  var_diesel,
  n_petrol,
  n_diesel,
  -- Calculate pooled standard error
  SQRT((var_petrol / n_petrol) + (var_diesel / n_diesel)) AS se,
  -- Calculate t-statistic
  (mean_petrol - mean_diesel) / NULLIF(SQRT((var_petrol / n_petrol) + (var_diesel / n_diesel)), 0) AS t_statistic
FROM pivot_stats
ORDER BY District;

-- 30.30-day and 90-day rolling average Price and Price_Change trends
SELECT
  Date,
  District,
  Fuel_Type,
  Price,
  Price_Change,
  ROUND(
    AVG(Price) OVER (
      PARTITION BY District, Fuel_Type 
      ORDER BY Date
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 2) AS Avg_Price_30d,
  ROUND(
    AVG(Price) OVER (
      PARTITION BY District, Fuel_Type 
      ORDER BY Date
      ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
    ), 2) AS Avg_Price_90d,
  ROUND(
    AVG(Price_Change) OVER (
      PARTITION BY District, Fuel_Type 
      ORDER BY Date
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 4) AS Avg_Price_Change_30d,
  ROUND(
    AVG(Price_Change) OVER (
      PARTITION BY District, Fuel_Type 
      ORDER BY Date
      ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
    ), 4) AS Avg_Price_Change_90d
FROM transformed_kerala_fuel_prices
ORDER BY District, Fuel_Type, Date;

-- 31. Year-over-year monthly comparison
SELECT
  District,
  Fuel_Type,
  YEAR(Converted_Date) AS Year,
  MONTH(Converted_Date) AS Month,
  ROUND(AVG(Price), 2) AS Avg_Monthly_Price,
  ROUND(AVG(Price_Change), 4) AS Avg_Monthly_Price_Change
FROM transformed_fuel_prices_view
GROUP BY District, Fuel_Type, Year, Month
ORDER BY District, Fuel_Type, Year, Month;

-- 32. Duplicate records with same District, Fuel Type, Price on different dates
SELECT 
  District,
  Fuel_Type,
  Price,
  COUNT(DISTINCT Date) AS Distinct_Dates,
  GROUP_CONCAT(DISTINCT Date ORDER BY Date) AS Dates_List
FROM transformed_kerala_fuel_prices
GROUP BY District, Fuel_Type, Price
HAVING Distinct_Dates > 1
ORDER BY Distinct_Dates DESC;

-- 33. Highest Fuel Prices Recorded in Each District
SELECT 
    District,
    Fuel_Type,
    Price,
    Converted_Date
FROM (
    SELECT 
        District,
        Fuel_Type,
        Price,
        Converted_Date,
        ROW_NUMBER() OVER (PARTITION BY District, Fuel_Type ORDER BY Price DESC) AS rn
    FROM transformed_fuel_prices_view
    WHERE Fuel_Type IN ('Petrol', 'Diesel')
) AS ranked
WHERE rn = 1
ORDER BY District, Fuel_Type;

-- 34. Lowest Fuel Prices Recorded in Each District

SELECT 
    District,
    Fuel_Type,
    Price,
    Converted_Date
FROM (
    SELECT 
        District,
        Fuel_Type,
        Price,
        Converted_Date,
        ROW_NUMBER() OVER (PARTITION BY District, Fuel_Type ORDER BY Price ASC) AS rn
    FROM transformed_fuel_prices_view
    WHERE Fuel_Type IN ('Petrol', 'Diesel')
) AS ranked
WHERE rn = 1
ORDER BY District, Fuel_Type;



