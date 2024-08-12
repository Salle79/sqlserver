-- Active: 1723293679881@@127.0.0.1@1433@Testie

-- Create the table in the specified schema
CREATE TABLE dbo.TestTable
(
    TableNameId INT NOT NULL PRIMARY KEY, -- primary key column
    Column1 [NVARCHAR](50) NOT NULL,
    Column2 [NVARCHAR](50) NOT NULL
    -- specify more columns here
);
GO