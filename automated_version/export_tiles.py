import os
import sys
import os
import time
import pandas as pd
from qgis.gui import (    
    QgsLayerTreeMapCanvasBridge
    )
from qgis.core import (
    QgsApplication,
    QgsProject,
    QgsMapSettings,
    QgsMapRendererParallelJob,
    QgsLayerTreeGroup,
    QgsCoordinateReferenceSystem,
    QgsDataSourceUri,
    QgsVectorLayer,
    QgsRectangle
)
from PyQt5.QtGui import QImage, QPainter, QColor
from PyQt5.QtCore import Qt, QRectF, QSize
from params import database_name, host, port, user, password
QGIS_PATH = "C:/OSGeo4W/apps/qgis"

############## Export tiles part
ROOT = "E:/codes/cadastre"
CODE_FOLDER = ROOT + "/automated_version"
STYLES_FOLDER = ROOT + "/styles"
OUTPUT_FOLDER_ROOT = ROOT + "/outputs"

############## Open the current_area control file (csv)
# Load the file
current_area = pd.read_csv(CODE_FOLDER + "/current_area.csv", sep=",")
print(current_area)
#Create the path to save the images
area_id = current_area['area_id'].iloc[0]
style = current_area['style'].iloc[0]
hex_color = current_area['background_color'].iloc[0]
OUTPUT_FOLDER = OUTPUT_FOLDER_ROOT + "/area_" + str(area_id)
print(OUTPUT_FOLDER)

# Define the connection parameters to PostGIS for QGIS project
uri = QgsDataSourceUri()
uri.setConnection(host, port, database_name, user, password)

# Define the list of layers to load
layers = [
    {"schema": "travail", "table": "feuille", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "parcelle", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "batiment", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "localisant", "geom_name":"bbox", "key": "id"},
    #{"schema": "travail", "table": "surfacehydrographique", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "coursdeau", "geom_name":"geom", "key": "id"},
    {"schema": "temporary", "table": "zone_name", "geom_name":"geom", "key": "id"},
    {"schema": "travail", "table": "annotationriviere", "geom_name":"bbox", "key": "id"},
    {"schema": "travail", "table": "annotationrue", "geom_name":"bbox", "key": "id"},
    {"schema": "travail", "table": "annotationcommune", "geom_name":"bbox", "key": "id"},
    {"schema": "travail", "table": "toponymeriviere", "geom_name":"geom", "key": "id"},
     {"schema": "travail", "table": "toponymerue", "geom_name":"geom", "key": "id"}
]

# Initialize QGIS application without GUI (headless mode)
QgsApplication.setPrefixPath(QGIS_PATH, True)
qgs = QgsApplication([], False)
qgs.initQgis()
print("QGIS initialized")

# Function to add PostGIS layer
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

def export_images(STYLES_FOLDER, OUTPUT_FOLDER):
    # Create a QgsProject instance
    project = QgsProject.instance()
    project.setCrs(QgsCoordinateReferenceSystem(2154))

    # Load and style the layers
    for layer_info in layers:
        layer = add_postgis_layer(uri, layer_info['schema'], layer_info['table'], layer_info['geom_name'])
        style_path = STYLES_FOLDER + f"/{style}/{layer_info['table']}.qml"
        print(style_path)
        apply_style(layer, style_path)
        project.addMapLayer(layer)

    # Map settings
    map_settings = QgsMapSettings()
    map_settings.setLayers([layer for layer in project.mapLayers().values()])  # Stack layers
    map_settings.setDestinationCrs(QgsCoordinateReferenceSystem.fromEpsgId(2154))  # EPSG:2154
    map_settings.setOutputSize(QSize(2000, 2000))  # Set output size
    map_settings.setBackgroundColor(QColor(hex_color))  # Set background color

    layer_zones = project.mapLayersByName('zone_name')[0]

    # Check if the layer is found in the project
    if layer_zones is None:
        print("The layer 'zone_name' hasn't been found.")
    else:
        for feature in layer_zones.getFeatures():
            print(feature)
            bbox = feature.geometry().boundingBox()
            id_zone = feature["id_zone"]
            map_settings.setExtent(QgsRectangle(bbox))
            xy = QgsRectangle(bbox).center()
            map_settings.computeExtentForScale(xy, 1250)

            # Render the map to an image
            image = QImage(QSize(2000, 2000), QImage.Format_ARGB32)
            image.fill(Qt.white)
            painter = QPainter(image)
            render = QgsMapRendererParallelJob(map_settings)
            
            def finished():
                output_path = OUTPUT_FOLDER + "/extrait_"+str(id_zone)+".png"
                print(output_path)
                render.renderedImage().save(output_path)

                # Calculate pixel size in the x and y directions
                width = bbox.width()
                height = bbox.height()

                pixel_size_x = width / image.width()
                pixel_size_y = (
                    -height / image.height()
                )  # Note: pixel size in y is negative in the world file

                # Upper-left corner coordinates
                upper_left_x = bbox.xMinimum()
                upper_left_y = bbox.yMaximum()

                # World file content
                world_file_content = [
                    f"{pixel_size_x:.10f}",  # Pixel size in the x direction
                    "0.0",  # Rotation term (usually 0)
                    "0.0",  # Rotation term (usually 0)
                    f"{pixel_size_y:.10f}",  # Pixel size in the y direction (negative)
                    f"{upper_left_x:.10f}",  # X coordinate of the upper-left corner
                    f"{upper_left_y:.10f}",  # Y coordinate of the upper-left corner
                ]

                # Write the world file
                world_file_path = output_path.replace(".png", ".pgw")
                with open(world_file_path, "w") as wf:
                    wf.write("\n".join(world_file_content))
                print(f"World file created at: {world_file_path}")
        
            render.finished.connect(finished)
            render.start()
            render.waitForFinished()
            painter.end()

if __name__ == "__main__":
    export_images(STYLES_FOLDER, OUTPUT_FOLDER)