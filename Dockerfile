# Use the official Microsoft SQL Server image
FROM mcr.microsoft.com/mssql/server:2019-latest

# Set environment variables
ENV SA_PASSWORD=YourStrong!Passw0rd
ENV ACCEPT_EULA=Y

# Expose the SQL Server port
EXPOSE 1433

# Switch to root user
USER root
# Optional: Copy a script to set up your database
# COPY setup.sql /usr/src/setup.sql

# Optional: Run the script after SQL Server starts
# CMD /opt/mssql/bin/sqlservr & sleep 30 && /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -i /usr/src/setup.sql