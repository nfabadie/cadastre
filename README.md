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

```sql
 CREATE EXTENSION postgis;
 ```

Puis créer un nouveau schéma nommé "travail" pour y charger les données.

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

Voici la liste des noms des tables à fournir pour chacun des fichiers, **en respectant la casse**:
* parcelle.shp --> parcelle
* feuille.shp --> feuille
* localisant.shp --> localisant
* batiment.shp --> batiment
* cours_d_eau.shp --> coursdeau
* troncon_de_route.shp --> tronconderoute

## Génération automatique des zones et des annotations

Sous PgAdmin 4, rafraichir la base "cadastre" et aller s'assurer que les 6 tables de données ont été ajoutées dans le schéma "travail". Puis ouvrir l'interface de requêtes (Menu: Tools/Query Tool) et ouvrir et exécuter les scripts 1 à 7 dans l'ordre croissant de numérotation.

* **1-DecoupageZones.sql**: Ce script génère une grille de 10*10 carrés de 662 mètres de côté. Ces zones serviront de base pour générer les images de cartes à l'échelle 1:1250 de 2000 pixels de côté. Il génère au passage un schéma par zone dans lequel il créer et peuple une copie locale de chacune des tables du schéma "travail" contenant les données de la table d'origine pour la zone concernée.

Comment savoir si tout s'est bien passé? 

A la fin de l'exécution du script, ouvrir un nouveau projet QGIS vide. Aller dans le menu Couche/Ajouter une couche/Ajouter des couches PostGIS et connectez-vous à la base "cadastre". Dans le schéma travail, sélectionnez les tables parcelle, feuille, localisant, batiment, coursdeau et tronconderoute. Dans le schéma temporary, sélectionnez la table zone_name. Placez "zone_name" en haut de la liste des couches QGIS et vérifiez visuellement si votre grille se superpose bien aux autres couches de données. Sinon, il faut la décaler en modifiant les valeurs des variables "decalage_x" et "decalage_y".

## Préparation et export des cartes au format image

