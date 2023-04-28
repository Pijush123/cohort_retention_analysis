
; with retail_data as
(
SELECT [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
FROM [customer_retention_analysis].[dbo].[retail_data]

  --- there are 541909 records in total

 --- where CustomerID = 0

  --- 7665 Customer have no ID

  where customerID !=0

  --- 406829 Customers have ID
)
, customer_table1 as 
(

SELECT * FROM retail_data
WHERE Quantity > 0 and UnitPrice > 0

--- We have got 397884 valid records
), dup_check as
(

--- Lets us do the duplicate check

SELECT*, ROW_NUMBER() OVER (PARTITION BY invoiceNo, StockCode, quantity ORDER BY InvoiceDate) as duplicate_flag
FROM customer_table1

)

SELECT *
INTO #retail_main_df  --- Here we are passing the clean table into a local tamp table named retail_main_df
FROM dup_check
---WHERE duplicate_flag > 1
WHERE duplicate_flag = 1

--- there are 5125 duplicate records
--- 392669 rows contains no duplicate


--- This is our Clean data set
--- Lets start the Cohort analysis
SELECT* from #retail_main_df

--- Lets see the first date when the customer acquisition was started
--- Unique identifier (Unique CustomerID)
--- Revenue data


SELECT
	CustomerID,
	min(invoicedate) first_purchase_date,
	DATEFROMPARTS(year(min(InvoiceDate)), month(min(InvoiceDate)), 1) Cohort_Date
into #Cohort_df
	FROM #retail_main_df
	GROUP BY CustomerID

--- We have now two tamp table retail_main_df and Cohort_df

SELECT * 
FROM #Cohort_df

--- Lets create cohort index using both tables

SELECT 
	ci_main_df.*,
	cohort_index = year_diff * 12 + month_diff + 1
into #cohort_retention_df
FROM
(
SELECT
	rmm.*,
	year_diff = invoice_year - Cohort_year,
	month_diff = Invoice_month - Cohort_month

FROM 
(
	SELECT
	rm.*,
	c.Cohort_Date,
	YEAR(rm.InvoiceDate) Invoice_year,
	MONTH(rm.InvoiceDate) Invoice_month,
	YEAR (c.Cohort_Date) Cohort_year,
	MONTH(c.Cohort_Date) Cohort_month
	FROM #retail_main_df rm
	LEFT JOIN #Cohort_df c
	ON rm.CustomerID = c.CustomerID
		)rmm
)ci_main_df


SELECT * 
FROM #cohort_retention_df


---Pivot table

SELECT DISTINCT
		cohort_index
FROM #cohort_retention_df
ORDER BY cohort_index
--- We have 13 distinct values

SELECT *
into #cohort_pivot
FROM (

	SELECT DISTINCT
			CustomerID,
			Cohort_date,
			cohort_index
	FROM #cohort_retention_df
)table1

pivot
(COUNT(CustomerID)
for Cohort_Index IN
(
	[1],
	[2],
	[3],
	[4],
	[5],
	[6],
	[7],
	[8],
	[9],
	[10],
	[11],
	[12],
	[13])
	) as pivot_table
ORDER BY Cohort_Date


SELECT*
FROM #cohort_pivot
ORDER BY Cohort_Date

--- lets convert the values into percentage


SELECT cohort_date,
	(1.0*[1]/[1]*100) as [1],
	1.0*[2]/[1]*100 as [2],
	1.0*[3]/[1]*100 as [3],
	1.0*[4]/[1]*100 as [4],
	1.0*[5]/[1]*100 as [5],
	1.0*[6]/[1]*100 as [6],
	1.0*[7]/[1]*100 as [7],
	1.0*[8]/[1]*100 as [8],
	1.0*[9]/[1]*100 as [9],
	1.0*[10]/[1]*100 as [10],
	1.0*[11]/[1]*100 as [11],
	1.0*[12]/[1]*100 as [12],
	1.0*[13]/[1]*100 as [13]
into #r_c
FROM #cohort_pivot
ORDER BY Cohort_Date


--- Having a look at the both tables
SELECT*
FROM #cohort_pivot
ORDER BY Cohort_Date
------------------
SELECT* FROM #r_c
ORDER BY Cohort_Date