# Génération de données synthétiques pour extraire les textes du cadastre napoléonien

Les scripts de ce dépôt permettent de générer des images de cartes de cadastre annotées pour entraîner un modèle de reconnaissance de textes dans des cartes de style comparable.

Les scripts 1 à 7 sont des scripts PL/pgSQL à exécuter dans l'ordre de numérotation sous PostGIS. 
Le script 8 permet de générer des images de cartes 2000*2000 pixel à partir du projet QGIS CartesSynthetiques.

## Téléchargement des données de base

### Données parcellaire express

Les données de la base Parcellaire Express (PCI) sont téléchargeables par départements sur le site de l'IGN: https://geoservices.ign.fr/parcellaire-express-pci

Une fois le dossier télécharger et dézippé, on va utiliser les fichiers suivants:
* feuille.shp
* parcelle.shp
* batiment.shp
* localisant.shp

### Données BD TOPO 

Les données de la BD TOPO sont téléchargeables par départements sur le site de l'IGN: https://geoservices.ign.fr/bdtopo

Une fois le dossier télécharger et dézippé, on va utiliser les fichiers suivants:
* cours_d_eau.shp
* troncon_de_route.shp

## Préparation de la base de données PostGIS

Sous PgAdmin 4, créer une base de données vide nommée "cadastre" (préciser l'encodage: UTF-8). Dans l'interface de requêtes (Menu: Tools/Query Tool), entrer et exécuter la commande suivante :

''' CREATE EXTENSION postgis;'''

Sous QGIS, créer un nouveau projet vide et y charger les 6 fichiers *.shp (Menu: Couche/Ajouter une couche/Ajouter une couche vecteur).

Puis créer une nouvelle connexion avec la base PostGIS "cadastre": Menu: Couche/Ajouter une couche/Ajouter des couches PostGIS. Puis cliquer sur le bouton "Nouveau" et compléter le formulaire avec les valeurs suivantes:

* Nom: cadastre
* Host: localhost
* Base de données: cadastre

Puis dans l'encadré "Authentification/De base", entrer les id/pwd d'accès à votre serveur PostgreSQL et cliquer sur OK.

Une fois la connexion créée, cliquer sur le bouton "Connecter".

Aller dans le menu Base de données / DB Manager. Dans la fenêtre qui s'ouvre, sélectionner la base "cadastre" dans l'arborescence "Fournisseurs de données". Puis cliquer sur "Import de couche/fichier". Compléter le formulaire pour chacun des 6 fichiers précédemment chargés afin de les charger dans la base "cadastre" (une nouvelle table est créée pour chaque fichier). Par exemple pour le fichier parcelle.shp:

* Source: parcelle
* Schéma: travail
* Table: parcelle
* Clé primaire: id
* Colonne de géométrie: geom
* SCR Source: EPSG:2154 / RGF93 v1 - Lambert 93
* SCR Cible: EPSG:2154 / RGF93 v1 - Lambert 93
* Encodage: UTF-8
* Remplacer la table de destination si existante: oui
* Ne pas promouvoir en multi-partie: non
* Convertir les noms de champs en minuscules: oui
* Créer un index spatial: oui


## Génération automatique des zones et des annotations
## Préparation et export des cartes au format image

