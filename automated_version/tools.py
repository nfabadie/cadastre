import psycopg2
from connexion import conn
import os
import csv

def create_directory(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)
    print(f"Directory '{directory}' created successfully.")

def executesql(root_folder,sql_file):
    # Create a cursor object
    cur = conn.cursor()

    # Read the SQL script
    with open(root_folder + sql_file, "r") as file:
        sql_script = file.read()

    # Execute the SQL script
    cur.execute(sql_script)

    # Commit the changes and close the connection
    conn.commit()
    

def executesql_with_string_format(root_folder,sql_file,variables):
    # Create a cursor object
    cur = conn.cursor()

    # Read the SQL script
    with open(root_folder + sql_file, "r") as file:
        sql_script = file.read()

        # Replace the placeholders with the actual values
        for key, value in variables.items():
            sql_script = sql_script.replace(f'{key}', f'{value}')

    print(f'Execute {sql_file} with the following parameters {variables}')

    # Execute the SQL script
    cur.execute(sql_script)

    # Commit the changes and close the connection
    conn.commit()
    

def export_table_as_csv(schema_name,table_name,csv_path,csv_name):
    # Create a cursor object
    cur = conn.cursor()

    # Execute a SELECT query to fetch all rows from the table
    cur.execute(f"SELECT * FROM {schema_name}.{table_name}")

    # Fetch all rows and column names
    rows = cur.fetchall()
    columns = [desc[0] for desc in cur.description]

    # Close the cursor and connection
    cur.close()
    

    # Write the data to a CSV file
    with open(f'{csv_path}/{csv_name}.csv', 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)

        # Write the header row
        writer.writerow(columns)

        # Write the data rows
        writer.writerows(rows)

    print(f"Table '{table_name}' exported to '{csv_name}.csv' successfully.")