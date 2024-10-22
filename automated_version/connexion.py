import psycopg2
from params import database_name, host, port, user, password

# Connect to the PostgreSQL database
conn = psycopg2.connect(
    dbname=database_name,
    user=user,
    password=password,
    host=host,
    port=port
)