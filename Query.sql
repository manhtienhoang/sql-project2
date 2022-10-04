--Information on orders placed in 2013 and 2014
select 
	f.SalesOrderNumber
	, f.SalesOrderLineNumber
	, dp.ProductKey
	, dp.EnglishProductName
	, ds.SalesTerritoryCountry
	, f.SalesAmount
	, f.OrderQuantity 
from FactInternetSales f
join DimProduct dp
on f.ProductKey = dp.ProductKey
join DimSalesTerritory ds
on ds.SalesTerritoryKey = f.SalesTerritoryKey
where year(f.OrderDate) in (2013, 2014)

--InternetTotalSales and NumberofOrders of product by country 
select 
	ds.SalesTerritoryCountry
	, dp.ProductKey
	, dp.EnglishProductName
	, sum(f.SalesAmount) as InternetTotalSales
	, sum(f.OrderQuantity) as NumberofOrders
from FactInternetSales f
join DimProduct dp
on f.ProductKey = dp.ProductKey
join DimSalesTerritory ds
on ds.SalesTerritoryKey = f.SalesTerritoryKey
group by ds.SalesTerritoryCountry, dp.ProductKey, dp.EnglishProductName
order by ds.SalesTerritoryCountry

--%The share of each product's sales in each country's total sales
with A as(
	select 
		ds.SalesTerritoryCountry as SalesTerritoryCountry
		, dp.ProductKey as ProductKey
		, dp.EnglishProductName as EnglishProductName
		, sum(f.SalesAmount) as InternetTotalSales
	from FactInternetSales f
	join DimProduct dp
	on f.ProductKey = dp.ProductKey
	join DimSalesTerritory ds
	on ds.SalesTerritoryKey = f.SalesTerritoryKey
	group by ds.SalesTerritoryCountry, dp.ProductKey, dp.EnglishProductName
),
B as(
	select 
		ds.SalesTerritoryCountry as SalesTerritoryCountry
		, sum(f.SalesAmount) as InternetTotalSales
	from FactInternetSales f
	join DimProduct dp
	on f.ProductKey = dp.ProductKey
	join DimSalesTerritory ds
	on ds.SalesTerritoryKey = f.SalesTerritoryKey
	group by ds.SalesTerritoryCountry
)
select 
	A.SalesTerritoryCountry
	, A.ProductKey
	, A.EnglishProductName
	, A.InternetTotalSales
	, B.InternetTotalSales as TotalCountrySales
	, format((A.InternetTotalSales / B.InternetTotalSales), 'p') as PercentofTotalInCountry
from A
join B
on A.SalesTerritoryCountry = B.SalesTerritoryCountry
order by A.SalesTerritoryCountry, A.ProductKey

--Top 3 customers with the highest total monthly revenue per month
with A as(
	select 
		year(f.OrderDate) as year
		, month(f.OrderDate) as month
		, d.CustomerKey as CustomerKey, d.FirstName + ' ' + d.LastName as FullName
		, sum(f.SalesAmount) as MonthAmount
		, rank() over(partition by year(f.OrderDate), month(f.OrderDate) order by sum(f.SalesAmount) desc) as rank
	from FactInternetSales f
	join DimCustomer d
	on f.CustomerKey = d.CustomerKey
	group by year(f.OrderDate), month(f.OrderDate), d.CustomerKey, d.FirstName + ' ' + d.LastName
)
select 
	A.year as OrderYear
	, A.month as OrderMonth
	, A.CustomerKey
	, A.FullName
	, A.MonthAmount as CustomerMonthAmount
from A
where rank <= 3

--Total Sales by Year, Month
select 
	year(f.OrderDate) as OrderYear
	, month(f.OrderDate) as OrderMonth
	, sum(f.SalesAmount) as InternetMonthAmount
from FactInternetSales f
group by year(f.OrderDate), month(f.OrderDate)
order by year(f.OrderDate), month(f.OrderDate)

--%Revenue growth over the same period last year
with A as( 
	select 
		year(f.OrderDate) as year
		, month(f.OrderDate) as month
		, sum(f.SalesAmount) as Sales
	from FactInternetSales f
	group by year(f.OrderDate), month(f.OrderDate)
),
B as(
	select 
		year(f.OrderDate) as year
		, month(f.OrderDate) as month
		, sum(f.SalesAmount) as Sales
	from FactInternetSales f
	group by year(f.OrderDate), month(f.OrderDate)
)
select 
	A.year as OrderYear
	, A.month as OrderMonth
	, A.Sales as InternetMonthAmount
	, B.year
	, B.month
	, B.Sales as InternetMonthAmount_LY
	, format(((A.Sales - B.Sales)/B.Sales), 'p') as PercentSalesGrowth
from A
left join B
on A.year = B.year + 1 and A.month = B.month
--where A.year is not null and B.year is not null
order by A.year, A.month

