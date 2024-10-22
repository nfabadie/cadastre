import processing
from qgis.core import QgsProject

ROOT = "E:/codes/cadastre" #We don't use the params file because we execute this script in QGIS interpreter
layer_name = "tronconderoute" #!!! Layers name have to be the same as in the bdtopo.json and pci-express.json files

# Step 1: Retrieve all vector layers in the project
project = QgsProject.instance()
layers = [layer for layer in project.mapLayers().values() if isinstance(layer, QgsVectorLayer)]

# Ensure there are layers to merge
if len(layers) == 0:
    print("No layers found in the project.")
    exit()

# Step 2: Prepare layer paths (we need the source file paths or layer references)
input_layers = [layer for layer in layers]

# Step 3: Run the merge process using the native QGIS merge algorithm
merged_output_path = ROOT + f"/data/merged/{layer_name}.shp"  # Replace with your desired output path

# Step 4: Run the merge operation
merge_params = {
    'LAYERS': input_layers,           # Input layers to merge
    'CRS': layers[0].crs(),           # CRS to use (use the CRS of the first layer)
    'OUTPUT': merged_output_path      # Output file path
}

# Execute the merge algorithm
processing.run("native:mergevectorlayers", merge_params)

print(f"Merged layer saved to {merged_output_path}")
