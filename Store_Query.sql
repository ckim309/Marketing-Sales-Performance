-- CLEANING DATA --
-- removing column
ALTER TABLE Store..data1
DROP COLUMN [Row ID];
-- changing 0 to NULL in Discount column
UPDATE Store..data1 
SET Discount=NULL 
WHERE Discount=0
-- adding Cost column
ALTER TABLE Store..data1
ADD Cost float;
-- adding Revenue Without Discount column
ALTER TABLE Store..data1
ADD RevenueWithDiscount float;
-- filling RevenueNoDiscount column
UPDATE Store..data1
SET RevenueWithDiscount = Revenue*COALESCE(1 - Discount,1)
-- filling Cost column
UPDATE Store..data1
SET Cost = ((Revenue - (Revenue * (COALESCE(Discount,0)))) - Profit);

select *
from Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Paper';



-- LOOKING ONLY AT CALIFORNIA: WHERE SHOULD WE ALLOCATE MORE OF OUR RESOURCES --

-- total cost, revenue, profit NOT USED
SELECT 
	ROUND(SUM(Cost),2) AS TotalCost,
	ROUND(SUM(Revenue),2) AS TotalRevenue,
	ROUND(SUM(RevenueWithDiscount),2) AS RevenueWithDiscount,
	ROUND(SUM(Profit),2) AS TotalProfit,
	ROUND(SUM(RevenueWithDiscount)-SUM(Cost),2) AS PotentialProfit,
	ROUND(SUM(Quantity),2) AS TotalQuantity
FROM Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Tables';

-- average use of resources NOT USED
SELECT 
	Category, Segment,
	Category + ' ' + Segment AS CatSeg,
	ROUND(SUM(Quantity),2) AS TotalQuantity,
	ROUND(SUM(Revenue),2) AS TotalRevenue,
	ROUND(AVG(Discount),3) AS AvgDiscount,
	ROUND(SUM(Cost),2) AS TotalCost,
	ROUND(SUM(Profit),2) AS TotalProfit,
	ROUND((SUM(Cost)/325372.76),4)AS PercentageOfResourcesUsed,
	ROUND((SUM(Revenue)/457687.62),4) As PercentageOfRevenue,
	ROUND((SUM(Profit)/76381.32),4) As PercentageOfProfit,
	ROUND((SUM(Profit)/SUM(Cost)),4) AS ROI_Percent
FROM Store..data1
WHERE State LIKE 'Cal%'
GROUP BY Category, Segment, Category + ' ' + Segment
ORDER BY PercentageOfResourcesUsed DESC;

-- Sub-Category of Items: Average Cost, Discount, Revenue, Profit
SELECT 
	DISTINCT(SubCat),
	ROUND(AVG(Discount),2) AS AvgDiscount,
	ROUND(SUM(Quantity),2) AS TotalQuantity,
	ROUND(SUM(Revenue),2) AS TotalRevenue,
	ROUND(SUM(RevenueWithDiscount),2) AS TotalRevenueWithDiscount,
	ROUND(SUM(Cost),2) AS TotalCost,
	ROUND(SUM(Profit),2) AS TotalProfit,
	ROUND((SUM(Cost)/325372.76),4)AS PercentageOfResourcesUsed,
	ROUND((SUM(RevenueWithDiscount)/457687.62),4) As PercentageOfRevenue,
	ROUND((SUM(Profit)/SUM(RevenueWithDiscount)),4) AS ProfitMargin,
	ROUND((SUM(Profit)/SUM(Cost)),4) AS ROI_Percent
FROM Store..data1
WHERE State LIKE 'Cal%'
GROUP BY SubCat
ORDER BY ROI_Percent;

-- will people buy tables when it is discounted? No.
SELECT [Customer ID] AS Customer,
	SUM(Quantity) AS NumOfTables, 
	Discount
FROM Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Tables'
GROUP BY [Customer ID], Discount

-- SOLUTION: RAISE SALE PRICE OR REALLOCATE RESOURCES
-- Paper vs Tables
SELECT 
	YEAR(OrderDate) AS Year,
	SubCat,
	Category + ' ' + Segment AS CatSeg,
	ROUND(SUM(Quantity),2) AS TotalQuantity,
	ROUND(SUM(Revenue),2) AS TotalRevenue,
	ROUND(AVG(Discount),2) AS AvgDiscount,
	ROUND(SUM(RevenueWithDiscount),2) AS TotalRevenueWithDiscount,
	ROUND(SUM(Cost),2) AS TotalCost,
	ROUND(SUM(Profit),2) AS TotalProfit,
	ROUND((SUM(Cost)/325372.76),4)AS PercentageOfResourcesUsed,
	ROUND((SUM(Profit)/SUM(RevenueWithDiscount)),4) AS ProfitMargin,
	ROUND((SUM(Profit)/SUM(Cost)),4) AS ROI_Percent,
	ROUND(SUM(Revenue)/SUM(Quantity),2) AS RegularPricePerQuantity,
	ROUND(SUM(RevenueWithDiscount)/SUM(Quantity),2) AS DiscountedPricePerQuantity
FROM Store..data1
WHERE State LIKE 'Cal%' AND (SubCat = 'Paper'  OR SubCat = 'Tables')
GROUP BY SubCat, Category + ' ' + Segment, YEAR(OrderDate), Discount;

-- Current and Future Predictions of Tables vs Paper
SELECT
	SubCat,
	ROUND(AVG(Discount),2) AS Discount,
	-- current average quantity, cost, revenue, profit
	ROUND(SUM(Quantity)/4,2) AS AvgSoldPerYear,
	ROUND(SUM(Cost)/SUM(Quantity),2) AS AvgCostPerQuantity,
	ROUND(SUM(RevenueWithDiscount)/SUM(Quantity),2) AS AvgRevenueWithDiscount,
	ROUND(SUM(Profit)/SUM(Quantity),2) AS AvgProfitPerQuantity,
	-- potential cost, revenue, profit without discount (20%)
	ROUND((SUM(Cost)/SUM(Quantity)),2) AS PotentialAvgCostPerQuantity,
	ROUND(((SUM(RevenueWithDiscount)/SUM(Quantity))/(1-Discount)),2) AS PotentialAvgRevenueNoDiscount,
	ROUND(((SUM(RevenueWithDiscount)/(1-Discount))-SUM(Cost))/SUM(Quantity),2) AS PotentialAvgProfitPerQuantity,
	-- current total quantity, cost, revenue, profit
	SUM(Quantity) AS TotalSold,
	ROUND(SUM(Cost),2) AS CurrentCost,
	ROUND(SUM(RevenueWithDiscount),2) AS CurrentRevenueWithDiscount,
	ROUND(SUM(Profit),2) AS CurrentProfit,
	-- potential total quantity, cost, revenue, profit
	CASE
		WHEN Subcat = 'Paper'
			THEN (16757.95+36647.77)/8.05
		END AS PotentialQuantityPaper,
	CASE
		WHEN Subcat = 'Paper'
			THEN (4553*8.05)+ 8780.41
		END AS PotentialCostPaper,
	CASE
		WHEN Subcat = 'Paper'
			THEN (4553*15.36)+16757.95
		END AS PotentialRevenuePaper,
	CASE
		WHEN Subcat = 'Paper'
			THEN (4553*7.31) +7977.54
		END AS PotentialProfitPaper,
	CASE
		WHEN Subcat = 'Tables'  
			THEN ROUND(SUM(Revenue),2)
			END AS PotentialRevenueNoDiscountTables,
	CASE
		WHEN Subcat = 'Tables'  
			THEN ROUND(SUM(Revenue)-SUM(Cost),2)
			END AS PotentialProfitTables
FROM Store..data1
WHERE State LIKE 'Cal%' AND (SubCat = 'Paper'  OR SubCat = 'Tables')
GROUP BY SubCat, Discount;

-- YoY Paper vs Tables
SELECT
	DISTINCT YEAR(OrderDate) AS Date,
	SubCat,
	ROUND(AVG(Discount),2) AS Discount,
	ROUND(SUM(Cost)/SUM(Quantity),2) AS AvgCostPerQuantity,
	ROUND(SUM(RevenueWithDiscount)/SUM(Quantity),2) AS AvgRevenueWithDiscount,
	ROUND(SUM(Profit)/SUM(Quantity),2) AS AvgProfitPerQuantity,
	SUM(Quantity) AS TotalSoldPerYear,
	ROUND(SUM(Cost),2) AS CurrentCost,
	ROUND(SUM(RevenueWithDiscount),2) AS CurrentRevenueWithDiscount,
	ROUND(SUM(Profit),2) AS CurrentProfit
FROM Store..data1
WHERE State LIKE 'Cal%' AND (SubCat = 'Paper'  OR SubCat = 'Tables')
GROUP BY SubCat,YEAR(OrderDate);


-- adding future values to temp table
INSERT INTO YoY_PvT (Date, SubCat, Discount, AvgCostPerQuantity, AvgRevenueWithDiscount, AvgProfitPerQuantity, TotalSoldPerYear,
	CurrentCost, CurrentRevenueWithDiscount, CurrentProfit)
VALUES 
	(2018, 'Paper', NULL, 8.05, 15.36, 7.31, 273, 8.05*273, 15.36*273, 7.31*273),
	(2018, 'Tables', 0.2, 130.42, 129.34, -1.08, 71, 130.42*273, 129.34*273, -1.08*273),
	(2019, 'Paper', NULL, 8.05, 15.36, 7.31, 273, 8.05*273, 15.36*273, 7.31*273),
	(2019, 'Tables', 0.2, 130.42, 129.34, -1.08, 71, 130.42*273, 129.34*273, -1.08*273),
	(2020, 'Paper', NULL, 8.05, 15.36, 7.31, 273, 8.05*273, 15.36*273, 7.31*273),
	(2020, 'Tables', 0.2, 130.42, 129.34, -1.08, 71, 130.42*273, 129.34*273, -1.08*273),
	(2021, 'Paper', NULL, 8.05, 15.36, 7.31, 273, 8.05*273, 15.36*273, 7.31*273),
	(2021, 'Tables', 0.2, 130.42, 129.34, -1.08, 71, 130.42*273, 129.34*273, -1.08*273),
	(2022, 'Paper', NULL, 8.05, 15.36, 7.31, 273, 8.05*273, 15.36*273, 7.31*273),
	(2022, 'Tables', 0.2, 130.42, 129.34, -1.08, 71, 130.42*273, 129.34*273, -1.08*273);

select *
from YoY_PvT

-- CTE
WITH CTE_PvTYoY
	(Date, SubCat, Discount, AvgCostPerQuantity, AvgRevenueWithDiscount, AvgProfitPerQuantity, TotalSoldPerYear,
	CurrentCost, CurrentRevenueWithDiscount, CurrentProfit)
	AS (
		SELECT
			DISTINCT YEAR(OrderDate) AS Date,
			SubCat,
			ROUND(AVG(Discount),2) AS Discount,
			ROUND(SUM(Cost)/SUM(Quantity),2) AS AvgCostPerQuantity,
			ROUND(SUM(RevenueWithDiscount)/SUM(Quantity),2) AS AvgRevenueWithDiscount,
			ROUND(SUM(Profit)/SUM(Quantity),2) AS AvgProfitPerQuantity,
			SUM(Quantity) AS TotalSoldPerYear,
			ROUND(SUM(Cost),2) AS CurrentCost,
			ROUND(SUM(RevenueWithDiscount),2) AS CurrentRevenueWithDiscount,
			ROUND(SUM(Profit),2) AS CurrentProfit
		FROM Store..data1
		WHERE State LIKE 'Cal%' AND (SubCat = 'Paper'  OR SubCat = 'Tables')
		GROUP BY SubCat,YEAR(OrderDate))
SELECT *
FROM CTE_PvTYoY
ORDER BY Date




-- LINEAR REGRESSION --
-- predicting sales and profit for next 5 years
SELECT
	DISTINCT YEAR(OrderDate) AS Date,
	SubCat,
	ROUND(AVG(Discount),2) AS Discount,
	ROUND(SUM(Cost)/SUM(Quantity),2) AS AvgCostPerQuantity,
	ROUND(SUM(RevenueWithDiscount)/SUM(Quantity),2) AS AvgRevenueWithDiscount,
	ROUND(SUM(Profit)/SUM(Quantity),2) AS AvgProfitPerQuantity,
	SUM(Quantity) AS TotalSoldPerYear,
	ROUND(SUM(Cost),2) AS CurrentCost,
	ROUND(SUM(RevenueWithDiscount),2) AS CurrentRevenueWithDiscount,
	ROUND(SUM(Profit),2) AS CurrentProfit
FROM Store..data1
WHERE State LIKE 'Cal%' AND (SubCat = 'Paper'  OR SubCat = 'Tables')
GROUP BY SubCat,YEAR(OrderDate);
-----------------
SELECT 
	SubCat, YEAR(OrderDate),
	ROUND(SUM(Cost)/SUM(Quantity),2) AS X,
	SQUARE(ROUND(SUM(Cost)/SUM(Quantity),2)) AS X2,
	SUM(Quantity) AS Y,
	(SUM(Quantity)*SUM(Quantity)) AS Y2,
	Quantity*SUM(ROUND(SUM(Cost)/SUM(Quantity),2)) AS XY,
	SUM(Quantity) AS N
FROM Store..data1
WHERE YEAR(OrderDate) BETWEEN 2014 AND 2017 AND (SubCat = 'Paper'  OR SubCat = 'Tables')
GROUP BY SubCat,YEAR(OrderDate)

-- linear regression
select 
	Subcat,
	((Y*X2)-(X*XY))/((N*X2)-X2) AS a,
	((N*XY)-(X * XY))/((N*x2)-x2) AS b
FROM LR 
WHERE SubCat = 'Paper' OR SubCat = 'Tables'

select *
FROM YoY_PvT

-- adding potential
ALTER TABLE YoY_PvT
ADD Slope_T float,
	Slope_P float;

-- adding the slope into temp table
ALTER TABLE YoY_PvT
ADD Slope_T float,
	Slope_P float;
UPDATE YoY_PvT
SET Slope_T = CASE
				WHEN SubCat = 'Paper'
				THEN (-5.20522817829555E-17 + (8.27303724719085*TotalSold))
				END
-- adding LumpTotalSold column into temp table

select subcat, TotalSoldPerYear,
	SUM(TotalSoldPerYear) OVER (PARTITION BY SubCat 
                         ORDER BY date 
                         ROWS 1 PRECEDING) AS LumpTotalSold
from YoY_PvT
group by subcat, date, TotalSoldPerYear
order by *














-- increaseing revenue to increase profit percentage
SELECT
	ROUND(SUM(Revenue)+(SUM(Revenue)*AVG(Discount))-SUM(Cost),2) AS PotentialProfit_NoDiscount,
	ROUND(100*(SUM(Revenue)+(SUM(Revenue)*AVG(Discount))-SUM(Cost))/SUM(Revenue),2) AS Potential_ProfitMargin,
	ROUND(100*(SUM(Revenue)+(SUM(Revenue)*AVG(Discount))-SUM(Cost))/SUM(Cost),2) AS PotentialROI
FROM Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Tables'

-- linear regression
SELECT DISTINCT(Year(OrderDate)) AS Year, 
	SUM(Quantity) AS NumOfSales,
	SUM(Cost)/SUM(Quantity) AS CurrentCostPerItem,
	SUM(Revenue)/SUM(Quantity) AS CurrentRevenuePerItem
FROM Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Tables'
GROUP BY Year(OrderDate);
-- averages
SELECT DISTINCT
	SUM(Quantity) AS AvgOfSales,
	SUM(Cost)/SUM(Quantity) AS AvgCostPerItem,
	SUM(Revenue)/SUM(Quantity) AS AvgRevenuePerItem
FROM Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Tables'















-- resource allocation
SELECT Category + ' ' + Segment AS CatSeg,
	ROUND(100*(SUM(Cost)/381306.24),2)AS PercentageOfResourcesUsed,
	ROUND(100*(SUM(Revenue)/457687.63),2) As PercentageOfRevenue
FROM Store..data1
WHERE State LIKE 'Cal%'
GROUP BY Category + ' ' + Segment
ORDER BY PercentageOfResourcesUsed DESC, PercentageOfRevenue DESC;

--ROI: where do we generate the most profit? --
SELECT Year(OrderDate) AS Year, 
	Category, Segment,
	Category + ' ' + Segment AS CatSeg,
	ROUND(SUM(Cost),2) AS TotalCost,
	ROUND(SUM(Revenue),2) AS TotalRevenue,
	ROUND(SUM(Profit),2) AS TotalProfit,
	SUM(Quantity) AS TotalQuantitySold,
	ROUND(SUM(Cost)/(SUM(Quantity)),2) AS CostPerQuantity,
	ROUND(SUM(Revenue)/(SUM(Quantity)),2) AS RevenuePerQuantity,
	ROUND((SUM(Profit)/SUM(Cost)),4) AS ROI_Percent
FROM Store..data1
WHERE State LIKE 'Cal%'
GROUP BY Category, Segment, Year(OrderDate)
ORDER BY Year

-- CTE: YoY profit growth (reveals how much value a business captures thorugh the price and cost of goods)
WITH YOY_Profit (Year, Category, Segment, TotalProfit, Previous_TotalProfit, YOY_ProfitDifference)
	AS (
		SELECT YEAR(OrderDate) AS Year,
			Category, Segment,
			ROUND(SUM(Profit),2) AS TotalProfit,
			ROUND(LAG(SUM(Profit)) OVER 
				(PARTITION BY Category, Segment ORDER BY YEAR(OrderDate)),2) AS Previous_TotalProfit,
			ROUND(SUM(Profit) - LAG(SUM(Profit)) 
				OVER(PARTITION BY Category, Segment ORDER BY YEAR(OrderDate)),2) AS YOY_TotalProfitDifference
		FROM Store..data1
		WHERE State LIKE 'Cal%' 
		GROUP BY Category, Segment, YEAR(OrderDate)
)
SELECT Year, Category, Segment, TotalProfit, Previous_TotalProfit, YOY_ProfitDifference,
	ROUND(YOY_ProfitDifference * 100/Previous_TotalProfit,2) AS YOY_GrowthPercentage
FROM YOY_Profit
GROUP BY  Year, Category, Segment, TotalProfit, Previous_TotalProfit, YOY_ProfitDifference;
--CTE: YoY revenue growth (reveals quantity demanded at a particular price)
WITH YOY_Revenue (Year, Category, Segment, TotalRevenue, Previous_TotalRevenue, YOY_RevenueDifference)
	AS (
		SELECT YEAR(OrderDate) AS Year,
			Category, Segment,
			ROUND(SUM(Revenue),2) AS TotalRevenue,
			ROUND(LAG(SUM(Revenue)) OVER 
				(PARTITION BY Category, Segment ORDER BY YEAR(OrderDate)),2) AS Previous_TotalRevenue,
			ROUND(SUM(Revenue) - LAG(SUM(Revenue)) 
				OVER(PARTITION BY Category, Segment ORDER BY YEAR(OrderDate)),2) AS YOY_RevenueDifference
		FROM Store..data1
		WHERE State LIKE 'Cal%' 
		GROUP BY Category, Segment, YEAR(OrderDate)
)
SELECT Year, Category, Segment, TotalRevenue, Previous_TotalRevenue, YOY_RevenueDifference,
	ROUND(YOY_RevenueDifference * 100/Previous_TotalRevenue,2) AS  YOY_Growth
FROM YOY_Revenue
GROUP BY  Year, Category, Segment, TotalRevenue, Previous_TotalRevenue, YOY_RevenueDifference;

