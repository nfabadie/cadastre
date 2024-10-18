import subprocess

# Variables
ROOT = "E:/codes/cadastre/automated_version"
SCRIPT_PATH = "sql_scripts/0-InitDatabase.sql"

# psql command to execute the script
command = "psql -U postgres -h localhost -p 5436 -f " + ROOT + '/' + SCRIPT_PATH

# Execute the command
subprocess.run(command, shell=True)