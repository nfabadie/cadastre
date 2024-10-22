# Import required modules
from qgis.core import (
    QgsApplication,
    QgsVectorLayer,
    QgsProject
)
import json
import time

ROOT = "E:/codes/cadastre" #We don't use the params file because we execute this script in QGIS interpreter
wfs_url = "https://data.geopf.fr/wfs/ows?"  # Replace with the actual WFS URL
crs_epsg = "EPSG:2154"

#Load list of depts to deal with
with open(ROOT + '/automated_version/layers/departements.json') as f:
    dept = json.load(f)
    #Make a list of the CODE values
    dept_list = [x['CODE'] for x in dept]

# Step 2: Define the WFS layer
wfs_layer_name = "CADASTRALPARCELS.PARCELLAIRE_EXPRESS:feuille"

# Create the full WFS URL with the typeName (layer name)
uri = f"{wfs_url}service=WFS&version=2.0.0&request=GetFeature&typeName={wfs_layer_name}&SRSNAME={crs_epsg}"
print(uri)

for dep in dept_list:
    # Step 3: Load the WFS layer
    layer = QgsVectorLayer(uri, dep, "WFS")

    # Check if the layer is valid
    if not layer.isValid():
        print("Failed to load the WFS layer")
    else:
        print("WFS layer loaded successfully")

    # Step 4: Apply filter (e.g., on the 'code_dept' field)
    # Example filter: Select features where 'code_dept' equals '75'
    filter_expression = f"code_dep = '{dep}'"
    layer.setSubsetString(filter_expression)
    #layer.setName(str(dep))

    # Optional: Add the layer to the project if needed
    QgsProject.instance().addMapLayer(layer)

    # Step 5: Work with the filtered layer (e.g., count features)
    feature_count = layer.featureCount()
    print(f"Number of features after applying filter: {feature_count}")

    #Sleep to not crash QGIS
    time.sleep(10)
