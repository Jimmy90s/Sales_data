---Inspecting Data
SELECT * FROM sales_data_csv

--CHecking unique values
SELECT DISTINCT status FROM sales_data_csv --Nice one to plot
SELECT DISTINCT year_id FROM sales_data_csv
SELECT DISTINCT PRODUCTLINE FROM sales_data_csv ---Nice to plot
SELECT DISTINCT COUNTRY FROM sales_data_csv ---Nice to plot
SELECT DISTINCT DEALSIZE FROM sales_data_csv ---Nice to plot
SELECT DISTINCT TERRITORY FROM sales_data_csv ---Nice to plot

SELECT DISTINCT MONTH_ID FROM sales_data_csv
WHERE year_id = 2005
ORDER BY 1 

---ANALYSIS
----Let's start by grouping sales by productline
SELECT PRODUCTLINE, SUM(sales) AS Revenue
FROM sales_data_csv
GROUP BY PRODUCTLINE
ORDER BY 2 DESC


SELECT YEAR_ID, SUM(sales) AS Revenue
FROM sales_data_csv
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT  DEALSIZE,  SUM(sales) AS Revenue
FROM sales_data_csv
GROUP BY  DEALSIZE
ORDER BY 2 DESC


----What was the best month FOR sales IN a specific year? How much was earned that month? 
SELECT  MONTH_ID 
	,SUM(sales) AS Revenue 
	,COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_csv
WHERE YEAR_ID = 2004 --change year to see the rest
GROUP BY  MONTH_ID
ORDER BY 2 DESC


--November seems to be the month, what product do they sell IN November, Classic I believe
SELECT  MONTH_ID
	,PRODUCTLINE
	,SUM(sales) AS Revenue
	,COUNT(ORDERNUMBER)
FROM sales_data_csv
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 --change year to see the rest
GROUP BY  MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


----Who is our best customer (this could be best answered with RFM)


DROP TABLE IF EXISTS #rfm;
WITH rfm AS 
(
	SELECT 
		CUSTOMERNAME
		,SUM(sales) AS MonetaryValue
		,AVG(sales) AS AvgMonetaryValue
		,COUNT(ORDERNUMBER) AS Frequency
		,MAX(ORDERDATE) AS last_order_date
		,(SELECT MAX(ORDERDATE) FROM sales_data_csv) AS max_order_date
		,DATEDIFF(D, MAX(ORDERDATE),(SELECT MAX(ORDERDATE) FROM sales_data_csv)) AS Recency
	FROM sales_data_csv
	GROUP BY CUSTOMERNAME
),
rfm_calc AS
(

	SELECT r.*,
		NTILE(10) OVER (ORDER BY Recency DESC) rfm_recency,
		NTILE(10) OVER (ORDER BY Frequency) rfm_frequency,
		NTILE(10) OVER (ORDER BY MonetaryValue) rfm_monetary
	FROM rfm r
)
SELECT 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary AS rfm_cell,
	CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary  AS VARCHAR)rfm_cell_string
INTO #rfm
FROM rfm_calc c

SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary
FROM #rfm
WHERE rfm_recency >= 8 AND
	rfm_frequency >= 8 AND
	rfm_monetary >= 8
ORDER BY CUSTOMERNAME 
/*
SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string IN (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		WHEN rfm_cell_string IN (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven?t purchased lately) slipping away
		WHEN rfm_cell_string IN (311, 411, 331) then 'new customers'
		WHEN rfm_cell_string IN (222, 223, 233, 322) then 'potential churners'
		WHEN rfm_cell_string IN (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string IN (433, 434, 443, 444) then 'loyal'
	END rfm_segment

FROM #rfm
*/

--What products are most often sold together? 
--SELECT * FROM sales_data_csv WHERE ORDERNUMBER =  10411

SELECT DISTINCT OrderNumber, stuff(

	(SELECT ', ' + PRODUCTCODE
	FROM sales_data_csv p
	WHERE ORDERNUMBER IN 
		(

			SELECT ORDERNUMBER
			FROM (
				SELECT ORDERNUMBER, COUNT(*) rn
				FROM sales_data_csv
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
			)m
			WHERE rn = 3
		)
		AND p.ORDERNUMBER = s.ORDERNUMBER
		FOR xml PATH (''))

		, 1, 1, '') ProductCodes

FROM sales_data_csv s
ORDER BY 2 DESC


---EXTRAs----
--What city has the highest number of sales IN a specific country
SELECT city, SUM (sales) Revenue
FROM sales_data_csv
WHERE country = 'UK'
GROUP BY city
ORDER BY 2 DESC



---What is the best product IN United States?
SELECT country, YEAR_ID, PRODUCTLINE, SUM(sales) Revenue
FROM sales_data_csv
WHERE country = 'USA'
GROUP BY  country, YEAR_ID, PRODUCTLINE
ORDER BY 4 DESC