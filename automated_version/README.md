### Pré-requis
- QGIS (OSGeo4W installer)
- Python

### Environnement virtuel Python
* Testé avec Python 3.10.8

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
**EN COURS DE REDACTION**
### 1. Création de la base de données "cadastre" et du schéma "travail"
1. Executer le script ```prepare_db.py``` pour créer la base de données *cadastre* et les schémas *travail* et *temporary*.
    * TO DO : Adapter les paramètres de connexion à votre serveur postgres et à vos identifiants
2. Executer ```1_load_layers```