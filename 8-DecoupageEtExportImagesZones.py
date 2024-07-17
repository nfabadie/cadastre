from qgis.core import (
    QgsProject,
    QgsMapSettings,
    QgsRectangle,
    QgsCoordinateReferenceSystem,
    QgsCoordinateTransform,
    QgsMapRendererParallelJob,
)
from qgis.gui import QgsMapCanvas
from qgis.PyQt.QtCore import QSize
from qgis.PyQt.QtGui import QPainter, QImage
import random

# Obtenir la référence de la vue cartographique principale
canvas = iface.mapCanvas()


# Fonction pour capturer un extrait de la carte
def capturer_extrait(bbox, id_bbox, taille_px):


    # Configurer les paramètres de la carte
    map_settings = QgsMapSettings()
    map_settings.setLayers(canvas.layers())
    map_settings.setExtent(bbox)
    map_settings.setOutputSize(QSize(taille_px, taille_px))

    # Capturer l'image
    image = QImage(taille_px, taille_px, QImage.Format_ARGB32)
    painter = QPainter(image)
    render = QgsMapRendererParallelJob(map_settings)

    def finished():
        output_path = "C:/Users/nfabadie/Documents/Stage2024/données/sortie/extrait_"+str(id_bbox)+".png"
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

# Taille de l'extrait en mètres et en pixels
taille_m = 662  # taille en mètres
taille_px = 2000  # taille en pixels

#On récupère les zones à découper
layer = QgsProject.instance().mapLayersByName('zone_name')[0]

# Vérifier si la couche a été trouvée
if layer is None:
    print("La couche 'zone_name' n'a pas été trouvée.")
else:
    # Itérer sur chaque entité de la couche
    for feature in layer.getFeatures():
        # Obtenir la géométrie de l'entité
        bbox = feature.geometry().boundingBox()
        id_zone = feature["id_zone"]
        capturer_extrait(bbox, id_zone, taille_px)
