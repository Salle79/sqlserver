CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    Department NVARCHAR(50) NULL,
    Salary DECIMAL(18, 2) NULL,
    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
)
WITH (SYSTEM_VERSIONING = OFF);

CREATE TABLE EmployeeHistory (
    EmployeeID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    Department NVARCHAR(50) NULL,
    Salary DECIMAL(18, 2) NULL,
    SysStartTime DATETIME2 NOT NULL,
    SysEndTime DATETIME2 NOT NULL
);

ALTER TABLE Employee
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));

SELECT * FROM AnotherTableName_Log

DROP TABLE #TablesToProcess;
CREATE TABLE #TablesToProcess
(
    TableName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    AddLoginColumn BIT -- New flag to indicate whether to add the login column
);

-- Insert table names and schemas with the flag
INSERT INTO #TablesToProcess (TableName, SchemaName, AddLoginColumn)
VALUES 
('SettingServiceExternal2', 'dbo', 1),
('AnotherTableName', 'dbo', 0);




DECLARE @MainTableName NVARCHAR(128)
DECLARE @HistoryTableName NVARCHAR(128)
DECLARE @SchemaName NVARCHAR(128)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @AddLoginColumn BIT

BEGIN TRANSACTION

DECLARE TableCursor CURSOR FOR
SELECT TableName, SchemaName, AddLoginColumn FROM #TablesToProcess

OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @MainTableName, @SchemaName, @AddLoginColumn

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Set the history table name
    SET @HistoryTableName = @MainTableName + '_Log'

    -- Step 2.1: Add the new columns and period columns to the existing table
    SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) + '
    ADD 
        workingUnit INT NULL,
        workingRole INT NULL,'
    
    -- Conditionally add the login column
    IF @AddLoginColumn = 1
    BEGIN
        SET @SQL = @SQL + 'login NVARCHAR(50) NOT NULL DEFAULT '''','
    END

    SET @SQL = @SQL + '
        SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
        SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
        PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);'

    -- Print the SQL to check before executing (developer only)
    PRINT @SQL

    -- Execute the dynamic SQL to add the columns
    EXEC sp_executesql @SQL

    -- Step 2.2: Generate the CREATE TABLE script for the history table
    SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' (' + CHAR(13)

    SELECT @SQL = @SQL + '    ' + QUOTENAME(c.COLUMN_NAME) + ' ' + c.DATA_TYPE + 
                   CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL AND c.DATA_TYPE IN ('nvarchar', 'varchar', 'char') THEN '(' + 
                   CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
                   ELSE '' END + ' ' + 
                   CASE WHEN c.IS_NULLABLE = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + ',' + CHAR(13)
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_NAME = @MainTableName AND c.TABLE_SCHEMA = @SchemaName
    AND c.COLUMN_NAME NOT IN ('SysStartTime', 'SysEndTime')

    -- Add the PERIOD columns to the history table
    SET @SQL = @SQL + '    SysStartTime DATETIME2 NOT NULL,' + CHAR(13)
    SET @SQL = @SQL + '    SysEndTime DATETIME2 NOT NULL' + CHAR(13)

    -- Remove the last comma and close the bracket
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1) + CHAR(13) + ');'

    -- Print the SQL to check before executing (optional)
    PRINT @SQL

    -- Execute the dynamic SQL to create the history table
    EXEC sp_executesql @SQL

    -- Step 2.3: Enable system versioning on the main table
    SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) +
               ' SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + '));'

    -- Print the SQL to check before executing (optional)
    PRINT @SQL

    -- Execute the dynamic SQL to enable system versioning
    EXEC sp_executesql @SQL

    -- Fetch the next table
    FETCH NEXT FROM TableCursor INTO @MainTableName, @SchemaName, @AddLoginColumn
END

CLOSE TableCursor
DEALLOCATE TableCursor
COMMIT TRANSACTION










DROP TABLE #TablesToProcess;
CREATE TABLE #TablesToProcess
(
    TableName NVARCHAR(128),
    SchemaName NVARCHAR(128)
);

CREATE TABLE AnotherTableName
(
    primaryKey INT NOT NULL PRIMARY KEY,
    label VARCHAR(20) NOT NULL,
    type INT NOT NULL,
    common VARCHAR(50) NULL,
    comments VARCHAR(200) NULL,
    owner INT NOT NULL,
);

CREATE TABLE SettingServiceExternal2
(
    primaryKey INT NOT NULL PRIMARY KEY,
    label VARCHAR(20) NOT NULL,
    type INT NOT NULL,
    common VARCHAR(50) NULL,
    comments VARCHAR(200) NULL,
    owner INT NOT NULL,
);


INSERT INTO #TablesToProcess (TableName, SchemaName)
VALUES 
('SettingServiceExternal2', 'dbo'),
('AnotherTableName', 'dbo');




DECLARE @MainTableName NVARCHAR(128)
DECLARE @HistoryTableName NVARCHAR(128)
DECLARE @SchemaName NVARCHAR(128)
DECLARE @SQL NVARCHAR(MAX)

BEGIN TRANSACTION
DECLARE TableCursor CURSOR FOR
SELECT TableName, SchemaName FROM #TablesToProcess

OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @MainTableName, @SchemaName

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Set the history table name
    SET @HistoryTableName = @MainTableName + '_Log'

    -- Step 2.1: Add the new columns and period columns to the existing table
    SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) + '
    ADD 
        workingUnit INT NULL,
        workingRole INT NULL,
        login NVARCHAR(50) NOT NULL DEFAULT '''',
        SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
        SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
        PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);'

    -- Print the SQL to check before executing (developer only)
    PRINT @SQL

    -- Execute the dynamic SQL to add the columns
    EXEC sp_executesql @SQL

    -- Step 2.2: Generate the CREATE TABLE script for the history table
    SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' (' + CHAR(13)

    SELECT @SQL = @SQL + '    ' + QUOTENAME(c.COLUMN_NAME) + ' ' + c.DATA_TYPE + 
                   CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL AND c.DATA_TYPE IN ('nvarchar', 'varchar', 'char') THEN '(' + 
                   CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
                   ELSE '' END + ' ' + 
                   CASE WHEN c.IS_NULLABLE = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + ',' + CHAR(13)
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_NAME = @MainTableName AND c.TABLE_SCHEMA = @SchemaName
    AND c.COLUMN_NAME NOT IN ('SysStartTime', 'SysEndTime')

    -- Add the PERIOD columns to the history table
    SET @SQL = @SQL + '    SysStartTime DATETIME2 NOT NULL,' + CHAR(13)
    SET @SQL = @SQL + '    SysEndTime DATETIME2 NOT NULL' + CHAR(13)

    -- Remove the last comma and close the bracket
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1) + CHAR(13) + ');'

    -- Print the SQL to check before executing (optional)
    PRINT @SQL

    -- Execute the dynamic SQL to create the history table
    EXEC sp_executesql @SQL

    -- Step 2.3: Enable system versioning on the main table
    SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) +
               ' SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + '));'

    -- Print the SQL to check before executing (optional)
    PRINT @SQL

    -- Execute the dynamic SQL to enable system versioning
    EXEC sp_executesql @SQL

    -- Fetch the next table
    FETCH NEXT FROM TableCursor INTO @MainTableName, @SchemaName
END

CLOSE TableCursor
DEALLOCATE TableCursor
COMMIT TRANSACTION


CREATE TABLE SettingServiceExternal2
(
    primaryKey INT NOT NULL PRIMARY KEY,
    label VARCHAR(20) NOT NULL,
    type INT NOT NULL,
    common VARCHAR(50) NULL,
    comments VARCHAR(200) NULL,
    owner INT NOT NULL,
);

ALTER TABLE dbo.SettingServiceExternal2
ADD 
    workingUnit INT NULL,
    workingRole INT NULL,
    login NVARCHAR(50) NOT NULL DEFAULT '',
    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);
    


DECLARE @MainTableName NVARCHAR(128) = 'SettingServiceExternal2' -- Main table name
DECLARE @HistoryTableName NVARCHAR(128) = @MainTableName + '_Log' -- History table name
DECLARE @SchemaName NVARCHAR(128) = 'dbo' -- Schema name
DECLARE @SQL NVARCHAR(MAX)

-- Generate the CREATE TABLE script for the history table
SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' (' + CHAR(13)

SELECT @SQL = @SQL + '    ' + QUOTENAME(c.COLUMN_NAME) + ' ' + c.DATA_TYPE + 
               CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL AND c.DATA_TYPE IN ('nvarchar', 'varchar', 'char') THEN '(' + 
               CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
               ELSE '' END + ' ' + 
               CASE WHEN c.IS_NULLABLE = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + ',' + CHAR(13)
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME = @MainTableName AND c.TABLE_SCHEMA = @SchemaName
AND c.COLUMN_NAME NOT IN ('SysStartTime', 'SysEndTime')

-- Add the PERIOD columns to the history table
SET @SQL = @SQL + '    SysStartTime DATETIME2 NOT NULL,' + CHAR(13)
SET @SQL = @SQL + '    SysEndTime DATETIME2 NOT NULL' + CHAR(13)

-- Remove the last comma and close the bracket
SET @SQL = LEFT(@SQL, LEN(@SQL) - 1) + CHAR(13) + ');'

-- Print the SQL to check before executing (optional)
PRINT @SQL

-- Execute the dynamic SQL to create the history table
EXEC sp_executesql @SQL


ALTER TABLE dbo.SettingServiceExternal2
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.SettingServiceExternal2_Log));











DROP TABLE #TablesToVersion;

CREATE TABLE #TablesToVersion
(
    TableName NVARCHAR(128),
    SchemaName NVARCHAR(128)
);


-- Insert your table names and schemas here
INSERT INTO #TablesToVersion (TableName, SchemaName)
VALUES ('SettingServiceExternallhello', 'dbo');


DECLARE @MainTableName NVARCHAR(128)
DECLARE @HistoryTableName NVARCHAR(128)
DECLARE @SchemaName NVARCHAR(128)
DECLARE @SQL NVARCHAR(MAX)

DECLARE TableCursor CURSOR FOR
SELECT TableName, SchemaName FROM #TablesToVersion

OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @MainTableName, @SchemaName

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Set the history table name
    SET @HistoryTableName = @MainTableName + '_Log'

    -- Generate the CREATE TABLE script for the history table
    SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' (' + CHAR(13)

    SELECT @SQL = @SQL + '    ' + QUOTENAME(c.COLUMN_NAME) + ' ' + c.DATA_TYPE + 
                   CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL AND c.DATA_TYPE IN ('nvarchar', 'varchar', 'char') THEN '(' + 
                   CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
                   ELSE '' END + ' ' + 
                   CASE WHEN c.IS_NULLABLE = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + ',' + CHAR(13)
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_NAME = @MainTableName AND c.TABLE_SCHEMA = @SchemaName
    AND c.COLUMN_NAME NOT IN ('SysStartTime', 'SysEndTime')

    -- Add the PERIOD columns to the history table
    SET @SQL = @SQL + '    SysStartTime DATETIME2 NOT NULL,' + CHAR(13)
    SET @SQL = @SQL + '    SysEndTime DATETIME2 NOT NULL' + CHAR(13)

    -- Remove the last comma and close the bracket
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1) + CHAR(13) + ');'

    -- Print the SQL to check before executing (optional)
    PRINT @SQL

    -- Execute the dynamic SQL to create the history table
    EXEC sp_executesql @SQL

    -- Enable system versioning on the main table
    SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@MainTableName) +
               ' SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + '));'

    -- Print the SQL to check before executing (optional)
    PRINT @SQL

    -- Execute the dynamic SQL to enable system versioning
    EXEC sp_executesql @SQL

    -- Fetch the next table
    FETCH NEXT FROM TableCursor INTO @MainTableName, @SchemaName
END

CLOSE TableCursor
DEALLOCATE TableCursor




CREATE TABLE SettingServiceExternallhelloo
(
    primaryKey INT NOT NULL PRIMARY KEY,
    label VARCHAR(20) NOT NULL,
    type INT NOT NULL,
    common VARCHAR(50) NULL,
    comments VARCHAR(200) NULL,
    owner INT NOT NULL,
    workingUnit INT NULL,
    workingRole INT NULL,
    login NVARCHAR(50) NOT NULL DEFAULT '',
    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
) 
WITH (SYSTEM_VERSIONING = OFF);


DECLARE @MainTableName NVARCHAR(128) = 'SettingServiceExternal' -- Main table name
DECLARE @HistoryTableName NVARCHAR(128) = @MainTableName + '_Log' -- History table name
DECLARE @SchemaName NVARCHAR(128) = 'dbo' -- Schema name

DECLARE @SQL NVARCHAR(MAX) = ''

-- Generate the CREATE TABLE script for the history table
SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' (' + CHAR(13)

SELECT @SQL = @SQL + '    ' + QUOTENAME(c.COLUMN_NAME) + ' ' + c.DATA_TYPE + 
               CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL AND c.DATA_TYPE IN ('nvarchar', 'varchar', 'char') THEN '(' + 
               CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
               ELSE '' END + ' ' + 
               CASE WHEN c.IS_NULLABLE = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + ',' + CHAR(13)
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME = @MainTableName AND c.TABLE_SCHEMA = @SchemaName
AND c.COLUMN_NAME NOT IN ('SysStartTime', 'SysEndTime')

-- Add the PERIOD columns to the history table
SET @SQL = @SQL + '    SysStartTime DATETIME2 NOT NULL,' + CHAR(13)
SET @SQL = @SQL + '    SysEndTime DATETIME2 NOT NULL' + CHAR(13)

-- Remove the last comma and close the bracket
SET @SQL = LEFT(@SQL, LEN(@SQL) - 1) + CHAR(13) + ');'

-- Print the SQL to check before executing
PRINT @SQL

-- Execute the dynamic SQL to create the history table
EXEC sp_executesql @SQL



ALTER TABLE dbo.SettingServiceExternal
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.SettingServiceExternal_Log));






DECLARE @MainTableName NVARCHAR(128) = 'SettingServiceExternal' -- Replace with your main table name
DECLARE @HistoryTableName NVARCHAR(128) = @MainTableName + '_Log'
DECLARE @SchemaName NVARCHAR(128) = 'spider3' -- Replace with your schema name

DECLARE @SQL NVARCHAR(MAX) = ''

-- Generate the CREATE TABLE script for the history table
SET @SQL = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@HistoryTableName) + ' (' + CHAR(13)

SELECT @SQL = @SQL + '    ' + QUOTENAME(c.COLUMN_NAME) + ' ' + c.DATA_TYPE + 
               CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL AND c.DATA_TYPE IN ('nvarchar', 'varchar', 'char') THEN '(' + 
               CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
               ELSE '' END + ' ' + 
               CASE WHEN c.IS_NULLABLE = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + ',' + CHAR(13)
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME = @MainTableName AND c.TABLE_SCHEMA = @SchemaName

-- Add the PERIOD columns to the history table
SET @SQL = @SQL + '    SysStartTime DATETIME2 NOT NULL,' + CHAR(13)
SET @SQL = @SQL + '    SysEndTime DATETIME2 NOT NULL,' + CHAR(13)
SET @SQL = @SQL + '    workingUnit INT NULL,' + CHAR(13)
SET @SQL = @SQL + '    workingRole INT NULL,' + CHAR(13)
SET @SQL = @SQL + '    login NVARCHAR(50) NOT NULL DEFAULT ''''' + CHAR(13)

-- Remove the last comma and close the bracket
SET @SQL = LEFT(@SQL, LEN(@SQL) - 1) + CHAR(13) + ');'

-- Print the SQL to check before executing
PRINT @SQL

-- Execute the dynamic SQL to create the history table
EXEC sp_executesql @SQL