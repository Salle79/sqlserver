import random
from faker import Faker
import datetime

fake = Faker()

# Set the start date for the HireDate field
start_date = datetime.datetime(2024, 1, 1)
end_date = datetime.datetime(2024, 12, 31)

# List of sample job titles
job_titles = [
    'Software Engineer', 'Project Manager', 'QA Engineer', 'Product Owner',
    'Business Analyst', 'HR Specialist', 'System Administrator', 'DevOps Engineer',
    'Database Administrator', 'Technical Support'
]

# Generate 1,000,000 sample entries
entries = []
start_range = 1
end_range = 1000001

salary_start_range = 50000
salary_end_range = 120000

for i in range(start_range, end_range):  # Start from 1 and go up to 1,000,000
    employee_id = i
    name = fake.first_name()
    last_name = fake.last_name()
    job_title = random.choice(job_titles)
    manager = random.choice([None, random.randint(start_range, end_range - 1)])  # Manager from existing records
    hire_date = fake.date_between(start_date=start_date, end_date=end_date).strftime('%Y-%m-%d')
    salary = round(random.uniform(salary_start_range, salary_end_range), 2)
    
    entries.append((employee_id, name, last_name, job_title, manager, hire_date, salary))

# Generate the SQL insert statements
batch_size = 10000
sql_insert_statements = []
for i in range(0, len(entries), batch_size):
    batch = entries[i:i+batch_size]
    values = []
    for entry in batch:
        manager_value = 'NULL' if entry[4] is None else entry[4]
        values.append(f"({entry[0]}, '{entry[1]}', '{entry[2]}', '{entry[3]}', {manager_value}, '{entry[5]}', {entry[6]})")
    
    sql_insert_statements.append(
        "INSERT INTO Employees (Employee_ID, Name, LastName, JobTitle, Manager, HireDate, Salary) VALUES\n" +
        ",\n".join(values) + ";"
    )

# Combine all the insert statements into one SQL script
sql_script = "\n".join(sql_insert_statements)

# Save the SQL script to a file
with open("insert_employees.sql", "w") as file:
    file.write(sql_script)