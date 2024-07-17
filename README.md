# Génération de données synthétiques pour extraire les textes du cadastre napoléonien

Les scripts de ce dépôt permettent de générer des images de cartes de cadastre annotées pour entraîner un modèle de reconnaissance de textes dans des cartes de style comparable.

Les scripts 1 à 7 sont des scripts PL/pgSQL à exécuter dans l'ordre de numérotation sous PostGIS. 
Le script 8 permet de générer des images de cartes 2000*2000 pixel à partir du projet QGIS CartesSynthetiques.

## Téléchargement des données de base

### Données parcellaire express

Les données de la base Parcellaire Express (PCI) sont téléchargeables par départements sur le site de l'IGN: https://geoservices.ign.fr/parcellaire-express-pci
Une fois le dossier télécharger et dézippé, on va utiliser les fichiers suivants:
feuille.shp
parcelle.shp
batiment.shp
localisant.shp

### Données BD TOPO 

Les données de la BD TOPO sont téléchargeables par départements sur le site de l'IGN: https://geoservices.ign.fr/bdtopo
Une fois le dossier télécharger et dézippé, on va utiliser les fichiers suivants:
cours_d_eau.shp
troncon_de_route.shp

## Préparartion de la base de données PostGIS
## Génération automatique des zones et des annotations
## Préparation et export des cartes au format image

