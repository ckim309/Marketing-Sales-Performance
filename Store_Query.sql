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



-- LOOKING AT CALIFORNIA: WHERE SHOULD WE ALLOCATE MORE OF OUR RESOURCES --

-- Sub-Category of Items Sold: Quantity, Profit, Revenue, Cost, Profit Margin, ROI
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
ORDER BY TotalProfit;

-- Assessing Problem: will people buy tables when it is not discounted? No.
SELECT [Customer ID] AS Customer,
	SUM(Quantity) AS NumOfTables, 
	Discount
FROM Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Tables'
GROUP BY [Customer ID], Discount

-- Solution: RAISE SALE PRICE OR REALLOCATE RESOURCES
-- YoY Analysis: Paper vs Tables
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

-- Current vs Future Analysis of Tables and Paper
SELECT
	SubCat,
	ROUND(AVG(Discount),2) AS Discount,
	-- current average quantity, cost, revenue, profit
	ROUND(SUM(Quantity)/4,2) AS AvgSoldPerYear,
	ROUND(SUM(Cost)/SUM(Quantity),2) AS AvgCostPerQuantity,
	ROUND(SUM(RevenueWithDiscount)/SUM(Quantity),2) AS AvgRevenueWithDiscount,
	ROUND(SUM(Profit)/SUM(Quantity),2) AS AvgProfitPerQuantity,
	-- potential average cost, revenue, profit without discount (20%)
	ROUND((SUM(Cost)/SUM(Quantity)),2) AS PotentialAvgCostPerQuantity,
	ROUND(((SUM(RevenueWithDiscount)/SUM(Quantity))/(1-Discount)),2) AS PotentialAvgRevenueNoDiscount,
	ROUND(((SUM(RevenueWithDiscount)/(1-Discount))-SUM(Cost))/SUM(Quantity),2) AS PotentialAvgProfitPerQuantity,
	-- current total quantity, cost, revenue, profit
	SUM(Quantity) AS TotalSold,
	ROUND(SUM(Cost),2) AS CurrentCost,
	ROUND(SUM(RevenueWithDiscount),2) AS CurrentRevenueWithDiscount,
	ROUND(SUM(Profit),2) AS CurrentProfit,
	-- potential revenue and profit for tables
	CASE
		WHEN Subcat = 'Tables'  
			THEN ROUND(SUM(Revenue),2)
			END AS PotentialRevenueNoDiscountTables,
	CASE
		WHEN Subcat = 'Tables'  
			THEN ROUND(SUM(Revenue)-SUM(Cost),2)
			END AS PotentialProfitTables,
	-- ROI and profit margin for potential sales in paper
	CASE
		WHEN Subcat = 'Tables'
		THEN (SUM(Revenue)-SUM(Cost))/SUM(Cost)
		END AS ROI_T,
	CASE
		WHEN Subcat = 'Tables'
		THEN (SUM(Revenue)-SUM(Cost))/(SUM(Revenue))
		END AS ProfitMargin_T,
	-- potential total quantity, cost, revenue, profit for paper
	CASE
		WHEN Subcat = 'Paper'
			THEN (SUM(Cost)+36647.77)/8.05
		END AS PotentialQuantityPaper,
	CASE
		WHEN Subcat = 'Paper'
			THEN SUM(Cost)+36647.77
		END AS PotentialCostPaper,
	CASE
		WHEN Subcat = 'Paper'
			THEN (SUM(RevenueWithDiscount)/SUM(Quantity))*((SUM(Cost)+36647.77)/8.05)
		END AS PotentialRevenuePaper,
	CASE
		WHEN Subcat = 'Paper'
			THEN (SUM(RevenueWithDiscount)/SUM(Quantity))*((SUM(Cost)+36647.77)/8.05) - (SUM(Cost)+36647.77)
		END AS PotentialProfitPaper,
	-- ROI and Profit Margine for potential sales in paper
	CASE
		WHEN Subcat = 'Paper'
		THEN ((SUM(RevenueWithDiscount)/SUM(Quantity))*((SUM(Cost)+36647.77)/8.05) - (SUM(Cost)+36647.77))/(SUM(Cost)+36647.77)
		END AS ROI_P,
	CASE
		WHEN Subcat = 'Paper'
		THEN ((SUM(RevenueWithDiscount)/SUM(Quantity))*((SUM(Cost)+36647.77)/8.05) - (SUM(Cost)+36647.77))/
			((SUM(RevenueWithDiscount)/SUM(Quantity))*((SUM(Cost)+36647.77)/8.05))
		END AS ProfitMargin_P
FROM Store..data1
WHERE State LIKE 'Cal%' AND (SubCat = 'Paper'  OR SubCat = 'Tables')
GROUP BY SubCat, Discount;

-- decreasing sales discount to 10% instead of 20% for tables
SELECT  	
	SubCat, 
	(Discount/2) AS NewDiscount,
	SUM(Quantity) AS TotalSold,
	ROUND((SUM(Cost)/SUM(Quantity)),2) AS AvgCostPerQuantity,
	-- potential revenue, profit
	ROUND(((SUM(RevenueWithDiscount)/SUM(Quantity))/(1-(Discount/2))),2) AS Dis10_RevenuePerQuantity,
	ROUND(((SUM(Revenue)-(SUM(Revenue)*(Discount/2))- SUM(Cost))/SUM(Quantity)),2) AS Dis10_ProfitPerQuantity,
	ROUND(SUM(RevenueWithDiscount),2) AS CurrentRevenueWithDiscount,
	ROUND(SUM(Cost),2) AS CurrentCost,
	ROUND(SUM(Profit),2) AS CurrentProfit,
	ROUND(SUM(Revenue)-(SUM(Revenue)*(Discount/2)),2) AS Revenue10Discount,
	ROUND((SUM(Revenue)-(SUM(Revenue)*(Discount/2)))- SUM(Cost),2) AS Profit10Discount,
	-- ROI and profit margin
	ROUND(((SUM(Revenue)-(SUM(Revenue)*(Discount/2)))- SUM(Cost))/SUM(Cost),2) AS Dis10_ROI,
	ROUND(((SUM(Revenue)-(SUM(Revenue)*(Discount/2)))- SUM(Cost))/(SUM(Revenue)-(SUM(Revenue)*(Discount/2))),4) AS Dis10_ProfitMargin
FROM Store..data1
WHERE State LIKE 'Cal%' AND SubCat = 'Tables'
GROUP BY SubCat, Discount;

-- CREATING TABLE TO ADD PREDICTIONS
CREATE TABLE #future (
	SubCat nvarchar(255), 
	Discount float, 
	TotalQuantity float, 
	TotalRevenue float, 
	TotalCost float, 
	TotalProfit float, 
	ProfitMargin float, 
	ROI_Percent float,
)
INSERT INTO #future
SELECT
	DISTINCT(SubCat),
	ROUND(AVG(Discount),2) AS Discount,
	ROUND(SUM(Quantity),2) AS TotalQuantity,
	ROUND(SUM(RevenueWithDiscount),2) AS TotalRevenue,
	ROUND(SUM(Cost),2) AS TotalCost,
	ROUND(SUM(Profit),2) AS TotalProfit,
	ROUND((SUM(Profit)/SUM(RevenueWithDiscount)),4) AS ProfitMargin,
	ROUND((SUM(Profit)/SUM(Cost)),4) AS ROI_Percent
FROM Store..data1
WHERE State LIKE 'Cal%'
GROUP BY SubCat
-- adding 10% discounted tables, no discount tables, newly invested paper
INSERT INTO #future (SubCat, Discount, TotalQuantity, TotalRevenue, 
	TotalCost, TotalProfit, ProfitMargin, ROI_Percent)
VALUES ('Tables 10', 0.1, 281, 40887.21, 36647.74, 4239.47, 0.1037, 0.12),
	('Tables_NoDisc', NULL, 281, 45430.23, 36647.74, 8782.49, 0.1933, 0.2396),
	('New_Paper', NULL, 5643, 86681.34, 45428.18, 41253.16, 0.47592, 0.9081)
-- percentage of cost, revenue and profit each category generates
SELECT SubCat, Discount, TotalQuantity, TotalRevenue, 
	TotalCost, TotalProfit, ProfitMargin, ROI_Percent,
	ROUND((SUM(TotalCost)/444096.33),4)AS PercentageOfResourcesUsed,
	ROUND((SUM(TotalRevenue)/630686.42),4) As PercentageOfRevenue,
	ROUND((SUM(TotalProfit)/130656.51),4) As PercentageOfProfit
FROM #future
GROUP BY SubCat, Discount, TotalQuantity, TotalRevenue, 
	TotalCost, TotalProfit, ProfitMargin, ROI_Percent
