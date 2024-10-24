DO $$ 
DECLARE
    tbl RECORD;
    i INT;
    j INT;
    min_x FLOAT;
    min_y FLOAT;
    max_x FLOAT;
    max_y FLOAT;
    max_x2 FLOAT;
    max_y2 FLOAT;
    zone_geom GEOMETRY;
    zone_name TEXT;
	zone_geom_wkt TEXT;

BEGIN
	-- On crée une table qui contient une seule ligne avec la surface couverte par l'ensemble des feuilles
	CREATE TABLE temporary.surfcadastre AS SELECT st_union(travail.feuille.geom) geom FROM travail.feuille;
	CREATE INDEX idx_sc ON temporary.surfcadastre USING GIST (geom);
    -- Coordonnées limites de la zone cadastrée:
    min_x := (SELECT ST_XMIN(geom) FROM temporary.surfcadastre);
    min_y := (SELECT ST_YMIN(geom) FROM temporary.surfcadastre);
	max_x := (SELECT ST_XMAX(geom) FROM temporary.surfcadastre);  
	max_y := (SELECT ST_YMAX(geom) FROM temporary.surfcadastre);  

    -- Création d'une table pour stocker le contour des zones à cartographier et exporter avec leurs annotations
    DROP TABLE IF EXISTS temporary.zone_name;
	CREATE TABLE temporary.zone_name(id_zone character varying(20), geom geometry(POLYGON, 2154));
	
	-- Initialisation des variables: chaque zone fait 662 mètres de côté (équiv. 2000 pixels à l'échelle 1:1250)
	i:=0; j:=0;
	max_x2:= min_x + 662; 
	max_y2:= min_y + 662; 
	
    -- Boucles pour générer les zones: on crée une grille sur l'ensemble des X,Y de la zone cadastrée
	WHILE max_x2 <= max_x LOOP
		WHILE max_y2 <= max_y LOOP
	
        -- Créer la géométrie de la zone			
            zone_geom := ST_MakeEnvelope(
                min_x + i * 662, 
                min_y + j * 662, 
                max_x2, 
                max_y2, 
                2154 -- SRS ID (ici du Lambert 93)
            );
			
		-- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_name := 'zone_' || i || '_' || j;
			
		-- Insertion des zones dans la table qui les stocke
			INSERT INTO temporary.zone_name(id_zone, geom) VALUES (zone_name, zone_geom);	
				
        j := j + 1;  max_y2:= min_y + (j + 1) * 662; -- Incrémenter les variables
		
		END LOOP;
		
	i := i + 1;  max_x2:= min_x + (i + 1) * 662; -- Incrémenter les variables
	-- Reinitialiser j et max_y2
	j := 0; max_y2 := min_y + 662;
	
    END LOOP;
	
	-- On indexe la table des zones
	CREATE INDEX idx_znn ON temporary.zone_name USING GIST (geom);

	-- On ne conserve que les zones dont la surface est entièrement en zone cadastrée: conserver la table zones!
	DROP TABLE IF EXISTS temporary.zones;
	CREATE TABLE temporary.zones AS 
	SELECT temporary.zone_name.id_zone as id_zone, ST_Intersection(temporary.zone_name.geom, surfcadastre.geom) AS geom FROM temporary.zone_name, temporary.surfcadastre WHERE ST_Intersects(temporary.zone_name.geom, surfcadastre.geom);
	DELETE FROM temporary.zones WHERE (ST_Area(geom)< 438244) ;
	
END $$;
