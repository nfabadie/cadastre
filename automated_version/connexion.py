import psycopg2

# Connect to the PostgreSQL database
conn = psycopg2.connect(
    dbname="cadastre",
    user="postgres",
    password="postgres",
    host="localhost",
    port="5436"
)