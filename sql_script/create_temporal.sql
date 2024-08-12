CREATE DATABASE Testie;

SELECT name 
FROM sys.databases
WHERE name = 'Testie';
---------------------------------
USE Testie;
--ALTER DATABASE [Testie]
--ADD FILEGROUP FG_Others;

ALTER DATABASE [Testie]
ADD FILEGROUP FG_Q1;

ALTER DATABASE [Testie]
ADD FILEGROUP FG_Q2;

ALTER DATABASE [Testie]
ADD FILEGROUP FG_Q3;

ALTER DATABASE [Testie]
ADD FILEGROUP FG_Q4;

SELECT name, type_desc
FROM sys.filegroups;
----------------------------
ALTER DATABASE [Testie]
ADD FILE
(
    NAME = N'FileGroup_Q1',
    FILENAME = N'/var/opt/mssql/data/FileGroup_Q1.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG_Q1;

ALTER DATABASE [Testie]
ADD FILE
(
    NAME = N'FileGroup_Q2',
    FILENAME = N'/var/opt/mssql/data/FileGroup_Q2.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG_Q2;

ALTER DATABASE [Testie]
ADD FILE
(
    NAME = N'FileGroup_Q3',
    FILENAME = N'/var/opt/mssql/data/FileGroup_Q3.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG_Q3;

ALTER DATABASE [Testie]
ADD FILE
(
    NAME = N'FileGroup_Q4',
    FILENAME = N'/var/opt/mssql/data/FileGroup_Q4.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG_Q4;

SELECT 
    fg.name AS FilegroupName, 
    f.name AS FileName, 
    f.physical_name AS FilePath, 
    f.size * 8 / 1024 AS SizeMB, 
    f.max_size / 128 AS MaxSizeMB, 
    f.growth * 8 / 1024 AS FileGrowthMB
FROM 
    sys.filegroups fg
JOIN 
    sys.database_files f 
ON 
    fg.data_space_id = f.data_space_id



-------------------------------------------------------------
CREATE PARTITION FUNCTION PF_HireDate (DATE)
AS RANGE RIGHT FOR VALUES 
(
    '2024-03-31',  -- End of Q1
    '2024-06-30',  -- End of Q2
    '2024-09-30'  -- End of Q3
);

SELECT name, type
FROM sys.partition_functions
WHERE name = 'PF_HireDate';

SELECT 
    pf.name AS PartitionFunction,
    prv.boundary_id AS BoundaryID,
    prv.value AS BoundaryValue
FROM 
    sys.partition_functions AS pf
JOIN 
    sys.partition_range_values AS prv
ON 
    pf.function_id = prv.function_id
WHERE 
    pf.name = 'PF_HireDate'
ORDER BY 
    prv.boundary_id;
    
    
SELECT 
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    p.rows AS NumberOfRows,
    fg.name AS FilegroupName
FROM 
    sys.partition_schemes ps
JOIN 
    sys.partition_functions pf ON ps.function_id = pf.function_id
JOIN 
    sys.partitions p ON p.partition_id = ps.data_space_id
JOIN 
    sys.filegroups fg ON fg.data_space_id = p.partition_id
WHERE 
    pf.name = 'PF_HireDate';    


---------------------------------------
CREATE PARTITION SCHEME PS_HireDate
AS PARTITION PF_HireDate
TO (FG_Q1, FG_Q2, FG_Q3, FG_Q4);

SELECT name
FROM sys.partition_schemes
WHERE name = 'PS_HireDate';


SELECT 
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    ds.destination_id AS PartitionNumber,
    fg.name AS FilegroupName
FROM 
    sys.partition_schemes ps
JOIN 
    sys.partition_functions pf ON ps.function_id = pf.function_id
JOIN 
    sys.destination_data_spaces ds ON ps.data_space_id = ds.partition_scheme_id
JOIN 
    sys.filegroups fg ON ds.data_space_id = fg.data_space_id
WHERE 
    ps.name = 'PS_HireDate'
ORDER BY 
    ds.destination_id;


SELECT 
    i.name AS IndexName,
    o.name AS TableName,
    ps.name AS PartitionScheme
FROM 
    sys.indexes i
JOIN 
    sys.objects o ON i.object_id = o.object_id
JOIN 
    sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
WHERE 
    ps.name = 'PS_HireDate';

--------------------------------------
CREATE TABLE Employees
(
    Employee_Id INT IDENTITY(1,1),
    Name NVARCHAR(100),
    LastName NVARCHAR(100),
    JobTitle NVARCHAR(100),
    Manager NVARCHAR(100),
    HireDate DATE NOT NULL,
    Salary DECIMAL(18, 2)
)
ON PS_HireDate(HireDate);

SELECT name, type_desc, temporal_type_desc
FROM sys.tables
WHERE name = 'Employees';

SELECT 
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    fg.name AS FileGroupName,
    p.partition_number,
    p.rows
FROM 
    sys.partitions p
JOIN 
    sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN 
    sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
JOIN 
    sys.partition_functions pf ON ps.function_id = pf.function_id
JOIN 
    sys.allocation_units au ON p.partition_id = au.container_id
JOIN 
    sys.filegroups fg ON fg.data_space_id = au.data_space_id
WHERE 
    OBJECT_NAME(p.object_id) = 'Employees'
ORDER BY 
    p.partition_number;



SET IDENTITY_INSERT Employees ON;

INSERT INTO Employees (Employee_Id, Name, LastName, JobTitle, Manager, HireDate, Salary)
VALUES 
(1, 'John', 'Doe', 'Software Developer', 'Jane Smith', '2024-01-15', 70000),
(2, 'Alice', 'Johnson', 'Data Analyst', 'Jane Smith', '2024-01-10', 60000),
(3, 'Bob', 'Williams', 'Project Manager', 'John Doe', '2024-01-05', 90000),
(4, 'Eva', 'Brown', 'HR Specialist', 'Alice Johnson', '2024-01-20', 50000);


CHECKPOINT;
DBCC FREESYSTEMCACHE('ALL');



----temporal----
---option1----- 
CREATE UNIQUE NONCLUSTERED INDEX UQ_Employee_Id_HireDate
ON Employees(Employee_Id, HireDate);

ALTER TABLE Employees
ADD CONSTRAINT PK_Employee_Id_HireDate PRIMARY KEY NONCLUSTERED (Employee_Id, HireDate);


---option 2-----
SELECT * INTO Employees_Backup FROM Employees;
SELECT * FROM Employees_Backup;

DROP TABLE Employees;

-- Drop the partition scheme
DROP PARTITION SCHEME PS_HireDate;

-- Drop the partition function
DROP PARTITION FUNCTION PF_HireDate;

CREATE TABLE Employees
(
    Employee_Id INT IDENTITY(1,1),
    Name NVARCHAR(100),
    LastName NVARCHAR(100),
    JobTitle NVARCHAR(100),
    Manager NVARCHAR(100),
    HireDate DATE NOT NULL,  -- Make HireDate non-nullable
    Salary DECIMAL(18, 2),
    CONSTRAINT PK_Employee_Id_HireDate PRIMARY KEY (Employee_Id, HireDate)
);

SET IDENTITY_INSERT Employees ON;

INSERT INTO Employees (Employee_Id, Name, LastName, JobTitle, Manager, HireDate, Salary)
SELECT Employee_Id, Name, LastName, JobTitle, Manager, HireDate, Salary
FROM Employees_Backup;

SET IDENTITY_INSERT Employees OFF;

CREATE PARTITION FUNCTION PF_HireDate (DATE)
AS RANGE RIGHT FOR VALUES 
(
    '2024-03-31',  -- End of Q1
    '2024-06-30',  -- End of Q2
    '2024-09-30'  -- End of Q3
);

-- Recreate the partition scheme
CREATE PARTITION SCHEME PS_HireDate
AS PARTITION PF_HireDate
TO (FG_Q1, FG_Q2, FG_Q3, FG_Q4);

-- Apply the partitioning to the table
ALTER TABLE Employees
DROP CONSTRAINT PK_Employee_Id_HireDate;

ALTER TABLE Employees
ADD CONSTRAINT PK_Employee_Id_HireDate PRIMARY KEY CLUSTERED (Employee_Id, HireDate)
ON PS_HireDate(HireDate);

DROP TABLE Employees_Backup;
DROP TABLE dbo.EmployeesHistory
-------------------end option2------------

CREATE TABLE dbo.EmployeesHistory
(
    Employee_Id INT NOT NULL,
    Name NVARCHAR(100),
    LastName NVARCHAR(100),
    JobTitle NVARCHAR(100),
    Manager NVARCHAR(100),
    HireDate DATE NOT NULL,
    Salary DECIMAL(18, 2),
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NOT NULL
);

ALTER TABLE Employees
ADD 
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL DEFAULT CONVERT(DATETIME2, '9999-12-31 23:59:59.9999999'),
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);



ALTER TABLE Employees
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeesHistory));



SELECT 
    t.name AS TableName, 
    t.temporal_type_desc AS TemporalType,
    h.name AS HistoryTableName
FROM 
    sys.tables t
LEFT JOIN 
    sys.tables h ON t.history_table_id = h.object_id
WHERE 
    t.name = 'Employees';

---utilities

SELECT 
    fg.name AS FilegroupName, 
    f.name AS FileName, 
    f.physical_name AS FilePath, 
    f.size * 8 / 1024 AS SizeMB, 
    f.max_size / 128 AS MaxSizeMB, 
    f.growth * 8 / 1024 AS FileGrowthMB
FROM 
    sys.filegroups fg
JOIN 
    sys.database_files f 
ON 
    fg.data_space_id = f.data_space_id


SELECT COUNT (*) FROM dbo.Employees;


SELECT
    DB_NAME(fs.database_id) AS DatabaseName,
    mf.physical_name AS FileName,
    fs.num_of_reads AS Reads,
    fs.num_of_writes AS Writes,
    fs.num_of_bytes_read / 1024 / 1024 AS MB_Read,
    fs.num_of_bytes_written / 1024 / 1024 AS MB_Written,
    fs.io_stall_read_ms AS ReadStallMS,
    fs.io_stall_write_ms AS WriteStallMS
FROM
    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
JOIN
    sys.master_files AS mf
ON
    fs.database_id = mf.database_id AND fs.file_id = mf.file_id;



SELECT $PARTITION.PF_HireDate(HireDate) AS PartitionNumber, *
FROM Employees
ORDER BY HireDate DESC;


SELECT 
    fg.name AS FilegroupName, 
    f.name AS FileName, 
    f.physical_name AS FilePath
FROM 
    sys.filegroups fg
JOIN 
    sys.database_files f 
ON 
    fg.data_space_id = f.data_space_id;



SELECT 
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    fg.name AS FileGroupName,
    p.partition_number,
    p.rows
FROM 
    sys.partitions p
JOIN 
    sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN 
    sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
JOIN 
    sys.partition_functions pf ON ps.function_id = pf.function_id
JOIN 
    sys.allocation_units au ON p.partition_id = au.container_id
JOIN 
    sys.filegroups fg ON fg.data_space_id = au.data_space_id
WHERE 
    OBJECT_NAME(p.object_id) = 'Employees'
ORDER BY 
    p.partition_number;


---alter functions---

ALTER DATABASE [Testie]
REMOVE FILE FileGroup_Q1; 

DBCC SHRINKFILE (FileGroup_Q1, EMPTYFILE);


DROP PARTITION SCHEME PS_HireDate;
DROP PARTITION FUNCTION PF_HireDate;


SELECT 
    fg.name AS FileGroupName,
    f.name AS FileName,
    f.physical_name AS FilePath,
    f.type_desc AS FileType,
    f.size * 8 / 1024 AS SizeMB,
    f.file_id
FROM 
    sys.filegroups fg
JOIN 
    sys.database_files f ON fg.data_space_id = f.data_space_id
ORDER BY 
    fg.name, f.file_id;
    
    
    
    
ALTER TABLE Employees
ADD CONSTRAINT PK_Employee_HireDate PRIMARY KEY (Employee_Id, HireDate)
ON PS_HireDate(HireDate);
    
    SELECT *
FROM Employees
WHERE HireDate IS NULL;

ALTER TABLE Employees
ALTER COLUMN HireDate DATE NOT NULL;



SELECT 
    name AS ObjectName, 
    type_desc AS ObjectType 
FROM 
    sys.objects 
WHERE 
    OBJECT_ID = OBJECT_ID('Employees') 
    AND OBJECT_ID IN (
        SELECT parent_object_id 
        FROM sys.foreign_keys 
        WHERE parent_object_id = OBJECT_ID('Employees')
    )
UNION
SELECT 
    i.name AS ObjectName, 
    'INDEX' AS ObjectType 
FROM 
    sys.indexes i 
INNER JOIN 
    sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id 
WHERE 
    i.object_id = OBJECT_ID('Employees') 
    AND ic.column_id = (
        SELECT column_id 
        FROM sys.columns 
        WHERE name = 'HireDate' 
        AND object_id = OBJECT_ID('Employees')
    );
