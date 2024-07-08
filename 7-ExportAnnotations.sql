DO $$ 
DECLARE
    i INT;
    j INT;
	x_min DOUBLE PRECISION;
	y_max DOUBLE PRECISION;
    zone_val TEXT;

BEGIN
DROP TABLE annotations;  
CREATE TABLE annotations(id serial PRIMARY KEY, id_zone character varying(10), texte character varying(100), nature character varying (20), xmin_ymin character varying(50), xmin_ymax character varying(50), xmax_ymax character varying(50), xmax_ymin character varying(50));	


    -- Boucle pour générer les zones
    FOR i IN 0..9 LOOP
        FOR j IN 0..9 LOOP

            -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_val := 'zone_' || i || '_' || j;
			
			-- Coord du point au nord est de la zone)
			x_min := (SELECT ST_XMin(temporary.zone_name.geom) FROM temporary.zone_name WHERE temporary.zone_name.id_zone like zone_val);
			y_max := (SELECT ST_YMax(temporary.zone_name.geom) FROM temporary.zone_name WHERE temporary.zone_name.id_zone like zone_val);
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (texte, id_zone, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT numero, temporary.zone_name.id_zone, coord_carto_to_image(ST_XMin(travail.localisant.bbox), ST_YMax(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.localisant.bbox), ST_YMin(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.localisant.bbox), ST_YMin(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.localisant.bbox), ST_YMax(travail.localisant.bbox),'||x_min||', '||y_max||')
			FROM travail.localisant, temporary.zone_name
			WHERE st_within(travail.localisant.geom, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''parcelle'' WHERE annotations.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (texte, id_zone, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT nom_com, temporary.zone_name.id_zone, coord_carto_to_image(ST_XMin(travail.feuille.bbox), ST_YMax(travail.feuille.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.feuille.bbox), ST_YMin(travail.feuille.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.feuille.bbox), ST_YMin(travail.feuille.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.feuille.bbox), ST_YMax(travail.feuille.bbox),'||x_min||', '||y_max||')
			FROM travail.feuille, temporary.zone_name
			WHERE st_within(travail.feuille.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''feuille'' WHERE annotations.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (texte, id_zone, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT text, temporary.zone_name.id_zone, coord_carto_to_image(ST_XMin(travail.rueentiere.bbox), ST_YMax(travail.rueentiere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.rueentiere.bbox), ST_YMin(travail.rueentiere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.rueentiere.bbox), ST_YMin(travail.rueentiere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.rueentiere.bbox), ST_YMax(travail.rueentiere.bbox),'||x_min||', '||y_max||')
			FROM travail.rueentiere, temporary.zone_name
			WHERE st_within(travail.rueentiere.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''rue'' WHERE annotations.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (texte, id_zone, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT text, temporary.zone_name.id_zone, coord_carto_to_image(ST_XMin(travail.riviere.bbox), ST_YMax(travail.riviere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.riviere.bbox), ST_YMin(travail.riviere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.riviere.bbox), ST_YMin(travail.riviere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.riviere.bbox), ST_YMax(travail.riviere.bbox),'||x_min||', '||y_max||')
			FROM travail.riviere, temporary.zone_name
			WHERE st_within(travail.riviere.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''riviere'' WHERE annotations.nature IS NULL;';
			
        END LOOP;
    END LOOP;
END $$;