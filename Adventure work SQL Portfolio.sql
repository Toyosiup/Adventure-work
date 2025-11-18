-- Omowunmi Olopade SQL PORTFOLIO

-- Show the top 3 customers with the highest order totals in each territory.
SELECT *
FROM (
    SELECT c.CustomerID, p.FirstName, p.LastName, soh.TerritoryID, SUM(soh.TotalDue) AS TotalSpent,
           RANK() OVER (PARTITION BY soh.TerritoryID ORDER BY SUM(soh.TotalDue) DESC) AS RankInTerritory
    FROM Sales.Customer c
    JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID, p.FirstName, p.LastName, soh.TerritoryID
) ranked
WHERE RankInTerritory <= 3;

-- Retrieve products where the average order quantity is greater than the overall average.
SELECT pr.ProductID, pr.Name, AVG(sod.OrderQty) AS AvgQty
FROM Sales.SalesOrderDetail sod
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
GROUP BY pr.ProductID, pr.Name
HAVING AVG(sod.OrderQty) > (SELECT AVG(OrderQty) FROM Sales.SalesOrderDetail);

-- Find the names of employees who have never sold anything.
SELECT e.BusinessEntityID, pp.FirstName, pp.LastName
FROM HumanResources.Employee e
JOIN Person.Person pp 
ON e.BusinessEntityID = pp.BusinessEntityID
WHERE e.BusinessEntityID NOT IN (
    SELECT DISTINCT SalesPersonID
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID IS NOT NULL);

-- Show the product categories that generate above-average revenue.
SELECT pc.Name AS CategoryName, SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
JOIN Production.ProductSubcategory ps ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
HAVING SUM(sod.LineTotal) > (
    SELECT AVG(CategoryRevenue)
    FROM (
        SELECT SUM(sod2.LineTotal) AS CategoryRevenue
        FROM Sales.SalesOrderDetail sod2
        JOIN Production.Product pr2 ON sod2.ProductID = pr2.ProductID
        JOIN Production.ProductSubcategory ps2 ON pr2.ProductSubcategoryID = ps2.ProductSubcategoryID
        JOIN Production.ProductCategory pc2 ON ps2.ProductCategoryID = pc2.ProductCategoryID
        GROUP BY pc2.Name)
    AS CategoryRevenues);

-- Find all customers whose first order total is higher than the average order total of all customers.
SELECT c.CustomerID, p.FirstName, p.LastName, soh.TotalDue
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE soh.SalesOrderID IN (
    SELECT MIN(SalesOrderID)
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID)
AND soh.TotalDue > (SELECT AVG(TotalDue) FROM Sales.SalesOrderHeader);

-- List employees and the number of different product categories their customers have purchased from.
SELECT e.BusinessEntityID, p.FirstName, p.LastName, COUNT(DISTINCT pc.ProductCategoryID) AS CategoryCount
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
JOIN Production.ProductSubcategory ps ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY e.BusinessEntityID, p.FirstName, p.LastName;

-- Show products ordered only once across the entire database.
SELECT ProductID, Name
FROM Production.Product
WHERE ProductID IN (
    SELECT ProductID
    FROM Sales.SalesOrderDetail
    GROUP BY ProductID
    HAVING SUM(OrderQty) = 1);


-- Find employees who earn more than the average salary of their department.
SELECT e.BusinessEntityID, pp.FirstName, pp.LastName, jh.Rate, e.JobTitle
FROM HumanResources.Employee e
JOIN HumanResources.EmployeePayHistory jh ON e.BusinessEntityID = jh.BusinessEntityID
JOIN Person.Person pp ON e.BusinessEntityID = pp.BusinessEntityID
WHERE jh.Rate > (
    SELECT AVG(Rate)
    FROM HumanResources.EmployeePayHistory eph
    JOIN HumanResources.Employee e2 ON eph.BusinessEntityID = e2.BusinessEntityID
    WHERE e2.OrganizationLevel = e.OrganizationLevel);

-- List customers who purchased products from more than 3 different territories.
SELECT c.CustomerID, p.FirstName, p.LastName, COUNT(DISTINCT soh.TerritoryID) AS Territories
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, p.FirstName, p.LastName
HAVING COUNT(DISTINCT soh.TerritoryID) > 3;

-- Show the most expensive product ordered in each order.
SELECT sod.SalesOrderID, sod.ProductID, pr.Name, sod.UnitPrice
FROM Sales.SalesOrderDetail sod
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
WHERE sod.UnitPrice = (
    SELECT MAX(UnitPrice)
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = sod.SalesOrderID);

    -- Retrieve the products that were ordered in every year of sales recorded.
SELECT pr.ProductID, pr.Name
FROM Production.Product pr
WHERE NOT EXISTS (
    SELECT DISTINCT YEAR(OrderDate)
    FROM Sales.SalesOrderHeader
    EXCEPT
    SELECT DISTINCT YEAR(soh.OrderDate)
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    WHERE sod.ProductID = pr.ProductID);


-- List employees who report to the same manager as a given employee (ID = 5).
SELECT e.BusinessEntityID, pp.FirstName, pp.LastName
FROM HumanResources.Employee e
JOIN Person.Person pp ON e.BusinessEntityID = pp.BusinessEntityID
WHERE e.OrganizationNode.GetAncestor(1) = (
    SELECT OrganizationNode.GetAncestor(1)
    FROM HumanResources.Employee
    WHERE BusinessEntityID = 5);

-- List customers who bought exactly the same set of products as another customer.
SELECT DISTINCT c1.CustomerID, c2.CustomerID
FROM Sales.Customer c1
JOIN Sales.Customer c2 ON c1.CustomerID < c2.CustomerID
WHERE NOT EXISTS (
    SELECT ProductID
    FROM Sales.SalesOrderDetail sod1
    JOIN Sales.SalesOrderHeader soh1 ON sod1.SalesOrderID = soh1.SalesOrderID
    WHERE soh1.CustomerID = c1.CustomerID
    EXCEPT
    SELECT ProductID
    FROM Sales.SalesOrderDetail sod2
    JOIN Sales.SalesOrderHeader soh2 ON sod2.SalesOrderID = soh2.SalesOrderID
    WHERE soh2.CustomerID = c2.CustomerID);

