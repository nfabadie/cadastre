# README.md

## Installation
### Pré-requis
- QGIS (OSGeo4W installer)
- Python

### Environnement virtuel Python
* Testé avec Python 3.10.8
```python
python -m venv .venv_synthmaps
#source .venv_synthmaps/bin/activate
```

### ogr2ogr depuis le terminal de commandes Windows
- Variables d'environnement à définir : 
    * Path : 
        * *C:\OSGeo4W\bin*
    * GDAL_DATA :
        * *C:\OSGeo4W\apps\gdal*
    * PROJ_LIB :
        * *C:\OSGeo4W\share\proj*
- Ouvrir une invite de command et taper *ogr2ogr* pour vérifier que ça fonctionne

### Utilisation de l'interpréteur Python de QGIS (sans le GUI)
1. Localiser le dossier qui contient l'interpréteur Python de QGIS (version d'OSGeoW4Shell) :
    * Windows : *C:\OSGeo4W\apps\Python312*
2. Copier-Coller le fichier exécutable *python.exe* dans le même dossier et le renommer *pythonqgis.exe*
3. Définir les variables d'environnement :
    * Path:
        * *C:\OSGeo4W\apps\Python312*
        * *C:\OSGeo4W\apps\Python312\pythonqgis*
    * PYTHONPATH:
        * *C:\OSGeo4W\apps\qgis\python*
        * *C:\OSGeo4W\apps\qgis\python\plugins*
        * *C:\OSGeo4W\apps\qgis\qtplugins*
        * *C:\OSGeo4W\apps\qt5\qtplugins*
4. Ouvrir l'invite de commande
5. Ecrire *pythonqgis* et valider. 
    * Si l'invite de commande bascule dans le mode Python, la configuration fonctionne.
    * Pour vérifier l'accès aux libs Python de QGIS : ```from qgis.core import *```
6. Utiliser ```subprocess``` pour utiliser cet interpréteur pour exécuter des scripts Python utilisant PyQGIS.

## Tutoriel "Création de dataset synthétique"

### 0. Création de la base de données
1. Ouvrir le fichier ```params.py``` et l'adapter à votre situation.
2. Créer une nouvelle base de données appelée *cadastre* dans Postgres.
3. Créer un schéma *travail* et un schéma *temporary* 
* Les deux dernières étapes peuvent être faites automatiquement avec le script ```0_prepare_db.py```.

### 1. Téléchargement des données

#### Cas général
* Suivre le processus de téléchargement indiqué dans le README principal du dépôt.

#### Alternative pour des couches géographiques **contenant peu d'objets**
* Utiliser le script ```1_download_data.py``` pour télécharger des données par le biais du flux WFS de l'IGN :
    * Paramétrez la variable ```wfs_layer_name``` en indiquant le nom de la couche WFS que vous qouhaitez télécharger.
    * Les données seront sélectionnées par département (la liste des départements est fournie dans le fichier ```departements.json```)

### 2. Aggréger les données de plusieurs départements (même couche)
1. Créez un projet QGIS vide.
2. Choisir une couche de la BDTOPO ou du PCI EXPRESS et charger le fichier correspondant de chaque département sélectionné (exemple : les couches ```PARCELLE.shp``` des départements 91,92,93,94,75,77,51)
3. Ouvrir l'**interpréteur Python de QGIS**:
    * Ouvrir le script ```2_concat_depts_data.py```.
    * Adapter le nom de la couche résultat et le dossier ROOT du projet.
    * Exécuter le script
    * La couche aggrégée est stockée dans le dossier *data/merged/*.

### 3. Ajouter les couches aggrégées à la base de données
1. Ouvrir le script dans votre éditeur de code ```3_load_layers_into_db.py```
2. Adapter les chemins de fichiers à votre situation
4. Exécuter le script depis votre terminal: les couches décrites dans les fichiers *bdtopo.json* et *pci-expresss.json* seront chargée dans la base de données *cadastre*.

### 4. Générer les coordonnées des zones (1 zone = 100 images)
1. Créez un nouveau projet QGIS et ajouter les couches aggrégées obtenues à l'étape précédente. 