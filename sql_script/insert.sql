USE Testie;

EXEC dbo.EnableSystemVersioning_V5
    @tableName = 'salleeee',
    @HistoryTableName = 'salleeee_Log',
    @schemaName = 'dbo',
    @AddExtraColumn = 0,
    @AddExtraColumn2 = 0;

CREATE TABLE salleeee (
    EmployeeID INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    Department NVARCHAR(50) NULL,
    Salary DECIMAL(18, 2) NULL,
)

CREATE OR ALTER PROCEDURE dbo.EnableSystemVersioning_V5
    @tableName NVARCHAR(128),
    @HistoryTableName NVARCHAR(128),
    @schemaName NVARCHAR(128),
    @AddExtraColumn BIT = 0, -- Flag to determine whether to add an extra column
    @AddExtraColumn2 BIT = 0 -- Flag to determine whether to add an extra column
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: Initialize the extra column variable
        DECLARE @extraColumn NVARCHAR(MAX) = '';
        DECLARE @extraColumn2 NVARCHAR(MAX) = '';
         
        -- Step 2: Set the extra column if the flag is set
        IF @AddExtraColumn = 1
        BEGIN
            SET @extraColumn = 'ExtraColumn NVARCHAR(50) NULL, '; -- Example of an additional column
        END
         IF @AddExtraColumn2 = 1
        BEGIN
            SET @extraColumn2 = 'ExtraColumn2 NVARCHAR(50) NULL, ExtraColumn3 NVARCHAR(50) NULL, ';
        END
        -- Step 3: Construct the dynamic SQL to alter the main table
        DECLARE @sql NVARCHAR(MAX);

        SET @sql = 
        'ALTER TABLE ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@tableName) + ' ADD ' +
        @extraColumn + @extraColumn2 +
        'ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN
            CONSTRAINT DF_' + @schemaName + '_' + @tableName + '_ValidFrom DEFAULT SYSUTCDATETIME(),
        ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN
            CONSTRAINT DF_' + @schemaName + '_' + @tableName + '_ValidTo DEFAULT CONVERT(DATETIME2, ''9999-12-31 23:59:59.9999999''),
        PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);';

        -- Print the SQL for debugging
        PRINT @sql;

        -- Execute the SQL
        EXEC sp_executesql @sql;

        -- Step 4: Enable System Versioning with the history table
        SET @sql = 'ALTER TABLE ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@tableName) + '
        SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@HistoryTableName) + '));';

        -- Print the SQL for debugging
        PRINT @sql;

        -- Execute the SQL
        EXEC sp_executesql @sql;

        -- Commit the transaction if all steps succeed
        COMMIT TRANSACTION;

        PRINT 'The table ' + @tableName + ' has been successfully converted to a temporal table with system versioning.';
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if any error occurs
        ROLLBACK TRANSACTION;

        -- Print error message
        PRINT 'An error occurred. The transaction has been rolled back.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END
GO