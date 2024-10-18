import os
import random
import csv
from qgis.core import (
    QgsProject, 
    QgsVectorLayer, 
    QgsFeature, 
    QgsGeometry, 
    QgsRectangle, 
    QgsSpatialIndex, 
    QgsVectorFileWriter,
    QgsDataSourceUri
)
from qgis.PyQt.QtCore import QVariant

# Parameters
ROOT = "E:/codes/cadastre"
STYLES_FOLDER = ROOT + "/styles"
N = 'ALL'  # Number of squares to randomly select, set to 'ALL' to select all squares
dept = "94"  # Example department code
style = "94_style1"  # Style to apply to the selected grid squares

#Fix parameters
grid_size = 6620  # Grid size (width and height in meters
project_crs_code = 2154
epsg_code = "EPSG:2154"
output_folder = ROOT + "/outputs/areas"  # Folder where the shapefiles will be saved

if not os.path.exists(output_folder):
    os.makedirs(output_folder)

#Functions
def add_postgis_layer(uri, schema, layer_name, geom_name):
    uri.setDataSource(schema, layer_name, geom_name)
    layer = QgsVectorLayer(uri.uri(), layer_name, "postgres")
    if not layer.isValid():
        print(f"Layer {layer_name} failed to load!")
    return layer

# Function to apply QML style
def apply_style(layer, qml_file):
    if os.path.exists(qml_file):
        layer.loadNamedStyle(qml_file)
        layer.triggerRepaint()

#Set QGIS project CRS
QgsProject.instance().setCrs(QgsCoordinateReferenceSystem(project_crs_code))

# Load layers from db to QGIS
uri = QgsDataSourceUri()
uri.setConnection("localhost", "5436", "cadastre", "postgres", "postgres")

# Define the list of layers to load from Postgis database
layers = [
    {"schema": "travail", "table": "feuille", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "parcelle", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "batiment", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "coursdeau", "geom_name":"geom", "key": "id"}
]

# Load and style the layers
for layer_info in layers:
    layer = add_postgis_layer(uri, layer_info['schema'], layer_info['table'], layer_info['geom_name'])
    QgsProject.instance().addMapLayer(layer)
    style_path = STYLES_FOLDER + f"/{style}/{layer_info['table']}.qml"
    apply_style(layer, style_path)

# Load layers
feuille_layer = QgsProject.instance().mapLayersByName('feuille')[0]
parcelle_layer = QgsProject.instance().mapLayersByName('parcelle')[0]

#Zoom on the extent of the layer feuille
iface.mapCanvas().setExtent(feuille_layer.extent())

# Get the extent of the "feuille" layer
feuille_extent = feuille_layer.extent()
xmin_feuille, ymin_feuille, xmax_feuille, ymax_feuille = (
    feuille_extent.xMinimum(), 
    feuille_extent.yMinimum(), 
    feuille_extent.xMaximum(), 
    feuille_extent.yMaximum()
)

# Create an empty memory layer for the grid
grid_layer = QgsVectorLayer(f'Polygon?crs={epsg_code}', 'Grid Layer', 'memory')
prov = grid_layer.dataProvider()

# Add fields: 'insee_dept', 'area_id', 'style', 'xmin', 'ymin', 'xmax', 'ymax'
prov.addAttributes([
    QgsField('insee_dept', QVariant.String),
    QgsField('area_id', QVariant.Int),
    QgsField('style', QVariant.String),
    QgsField('xmin', QVariant.Double),
    QgsField('ymin', QVariant.Double),
    QgsField('xmax', QVariant.Double),
    QgsField('ymax', QVariant.Double)
])
grid_layer.updateFields()

# Generate the grid based on the extent of the "feuille" layer
features = []
unique_id = 1
for x in range(int(xmin_feuille), int(xmax_feuille), grid_size):
    for y in range(int(ymin_feuille), int(ymax_feuille), grid_size):
        xmax = x + grid_size
        ymax = y + grid_size
        # Only include squares that are fully sized (i.e., 6620x6620)
        if xmax <= xmax_feuille and ymax <= ymax_feuille:
            rect = QgsRectangle(x, y, xmax, ymax)
            geom = QgsGeometry.fromRect(rect)
            
            # Create a new feature for each grid square
            feature = QgsFeature(grid_layer.fields())
            feature.setGeometry(geom)
            feature.setAttributes([dept, unique_id, style, x, y, xmax, ymax])
            features.append(feature)
            unique_id += 1

# Add grid features to the grid layer
prov.addFeatures(features)
grid_layer.updateExtents()

# Save the full grid before selection
full_grid_path = f"{output_folder}/{dept}_full_grid.shp"
QgsVectorFileWriter.writeAsVectorFormat(grid_layer, full_grid_path, "UTF-8", grid_layer.crs(), "ESRI Shapefile")
layer_full_grid = QgsVectorLayer(full_grid_path, "full_grid", "ogr")

print(f"Full grid saved as {full_grid_path}")

if N != 'ALL':
    # Step 1: Build a spatial index for the "parcelle" layer for efficient spatial queries
    parcelle_index = QgsSpatialIndex(parcelle_layer.getFeatures())

    # Step 2: Select grid squares that intersect with "parcelle" features
    selected_features = []
    for grid_feat in grid_layer.getFeatures():
        grid_geom = grid_feat.geometry()
        # Use the spatial index to find "parcelle" features intersecting with the grid square
        intersecting_parcelle_ids = parcelle_index.intersects(grid_geom.boundingBox())
        
        # Check if any of these features actually intersect the grid square
        for parcelle_id in intersecting_parcelle_ids:
            parcelle_feat = parcelle_layer.getFeature(parcelle_id)
            if grid_geom.intersects(parcelle_feat.geometry()):
                selected_features.append(grid_feat)
                break  # Stop checking other "parcelle" features for this grid square

    # Step 3: Randomly select N squares from the valid ones
    random_selected_features = random.sample(selected_features, N)

    # Step 4: Create a new layer for the selected grid squares
    selected_grid_layer = QgsVectorLayer(f'Polygon?crs={epsg_code}', 'Selected Grid Layer', 'memory')
    prov_selected = selected_grid_layer.dataProvider()
    prov_selected.addAttributes(grid_layer.fields())
    selected_grid_layer.updateFields()

    # Add selected features to the selected grid layer
    prov_selected.addFeatures(random_selected_features)
    selected_grid_layer.updateExtents()

    # Step 5: Save the selected grid squares as a shapefile
    selected_grid_path = f"{output_folder}/{dept}_selected_areas.shp"
    QgsVectorFileWriter.writeAsVectorFormat(selected_grid_layer, selected_grid_path, "UTF-8", selected_grid_layer.crs(), "ESRI Shapefile")
    print(f"Selected grid saved as {selected_grid_path}")
    layer_selection_grid = QgsVectorLayer(selected_grid_path, "selected_grid", "ogr")
    QgsProject.instance().addMapLayer(layer_selection_grid)
else:
    selected_grid_path = f"{output_folder}/{dept}_selected_areas.shp"
    QgsVectorFileWriter.writeAsVectorFormat(grid_layer, selected_grid_path, "UTF-8", grid_layer.crs(), "ESRI Shapefile")
    print(f"Selected grid saved as {selected_grid_path}")
    layer_selection_grid = QgsVectorLayer(selected_grid_path, "selected_grid", "ogr")
    QgsProject.instance().addMapLayer(grid_layer)

# Load the shapefile
shapefile_path = f"{output_folder}/{dept}_selected_areas.shp"
layer = QgsVectorLayer(shapefile_path, "selected_grid", "ogr")

if not layer.isValid():
    print(f"Layer failed to load: {shapefile_path}")
else:
    print("Shapefile loaded successfully")

# Prepare to write CSV
output_csv_path = ROOT + f"/automated_version/controls/{dept}_controls.csv"

# Get field names (attributes)
fields = [field.name() for field in layer.fields()]
print(fields)
# Open CSV file for writing
with open(output_csv_path, mode='w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)

    # Write the header (field names + geometry column)
    writer.writerow(fields)

    # Loop through features in the layer
    for feature in layer.getFeatures():
        # Get attribute values
        attributes = feature.attributes()

        # Write attributes and geometry to the CSV file
        writer.writerow(attributes)

print(f"CSV file has been created at: {output_csv_path}")