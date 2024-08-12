USE Testie;
SELECT * FROM dbo.Employees;
SELECT * FROM dbo.EmployeesHistory;
SELECT COUNT (*) FROM dbo.Employees;

SET IDENTITY_INSERT Employees OFF;
INSERT INTO Employees (Name, LastName, JobTitle, Manager, HireDate, Salary)
VALUES 
('John', 'Doe', 'Software Developer', 'Jane Smith', '2024-01-15', 70000),
('Alice', 'Johnson', 'Data Analyst', 'Jane Smith', '2024-01-10', 60000),
('Bob', 'Williams', 'Project Manager', 'John Doe', '2024-01-05', 90000),
('Eva', 'Brown', 'HR Specialist', 'Alice Johnson', '2024-01-20', 50000);