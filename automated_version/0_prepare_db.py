import subprocess
from params import BASE, user, host, port

# Variables
ROOT = BASE + "/automated_version"
SCRIPT_PATH = "sql_scripts/0-InitDatabase.sql"

# psql command to execute the script
command = f"psql -U {user} -h {host} -p {port} -f " + ROOT + '/' + SCRIPT_PATH

# Execute the command
subprocess.run(command, shell=True)