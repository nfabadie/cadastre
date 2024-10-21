import json
import subprocess
from params import BASE, database_name, host, port, user, password, schema, target_crs

ROOT = BASE + "/automated_version"

#These paths have to be adaptated to your situation
ROOT_BDTOPO = BASE + "/data/merged"
ROOT_PCI = BASE + "/data/merged"

# Construct the ogr2ogr command with Python variables
def create_ogr2ogr_command(database_name, host, port, user, password, shapefile_path, target_table_name, target_crs):
    command = f"""ogr2ogr \
    -f "PostgreSQL" PG:"dbname={database_name} host={host} port={port} user={user} password={password}" \
    "{shapefile_path}" \
    -nln {target_table_name} \
    -t_srs {target_crs} \
    -overwrite \
    -lco FID="id" \
    -lco SPATIAL_INDEX=GIST \
    -lco LAUNDER=YES \
    -lco GEOMETRY_NAME=geom \
    -lco PRECISION=NO \
    -lco ENCODING=UTF-8 \
    -fieldTypeToString All \
    -dim 2 \
    -explodecollections \
    --config PG_USE_COPY YES"""
    return command


if __name__ == "__main__":
    
    with open(ROOT + "/layers/bdtopo.json") as f:
        bdtopo = json.load(f)

    for elem in bdtopo:
        shapefile_path = ROOT_BDTOPO + '/' + elem['THEME'] + '/' + elem['LAYER'] + '.shp'
        table_name = elem['TABLE']
        target_table_name = schema + '.' + table_name
        command = create_ogr2ogr_command(database_name, host, port, user, password, shapefile_path, target_table_name, target_crs)
        subprocess.run(command, shell=True)

    with open(ROOT + "/layers/pci-express.json") as f:
        pci = json.load(f)

    for elem in pci:
        shapefile_path = ROOT_PCI + '/' + elem['LAYER'] + '.shp'
        table_name = elem['TABLE']
        target_table_name = schema + '.' + table_name
        command = create_ogr2ogr_command(database_name, host, port, user, password, shapefile_path, target_table_name, target_crs)
        subprocess.run(command, shell=True)
