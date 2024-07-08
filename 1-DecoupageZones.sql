DO $$ 
DECLARE
    tbl RECORD;
    i INT;
    j INT;
    min_x FLOAT;
    min_y FLOAT;
    max_x FLOAT;
    max_y FLOAT;
    zone_geom GEOMETRY;
    zone_name TEXT;

BEGIN
    -- Coordonnées limites de votre zone d'étude (à adapter selon vos données)
    min_x := (SELECT (ST_XMIN(ST_Union(geom))+5000) FROM travail.feuille);
    min_y := (SELECT (ST_YMIN(ST_Union(geom))+5000) FROM travail.feuille);
    max_x := min_x+ 6620; -- 662 pixels * 15 (pour 15 zones de 662pixels)
    max_y := min_y+ 6620; -- 662 pixels * 15 (pour 15 zones de 662pixels)
	

    -- Création d'une table pour stocker le contour de la zone
    DROP TABLE temporary.zone_name;
	CREATE TABLE temporary.zone_name(id_zone character varying(10), geom geometry(POLYGON, 2154));
	
	
    -- Boucle pour générer les zones
    FOR i IN 0..9 LOOP
        FOR j IN 0..9 LOOP
            -- Créer la géométrie de la zone
            zone_geom := ST_MakeEnvelope(
                min_x + i * 662, 
                min_y + j * 662, 
                min_x + (i + 1) * 662, 
                min_y + (j + 1) * 662, 
                2154 -- SRS ID (ici du Lambert 93)
            );

            -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_name := 'zone_' || i || '_' || j;
			
			-- Insertion des zones dans la table qui les stocke
			INSERT INTO temporary.zone_name(id_zone, geom) VALUES (zone_name, zone_geom);
			
				-- Création des schémas
			EXECUTE 'DROP SCHEMA IF EXISTS '|| zone_name ||' CASCADE ;';
			EXECUTE 'CREATE SCHEMA IF NOT EXISTS '|| zone_name ||';';
			
            -- Boucle sur chaque table de votre schéma
            FOR tbl IN
                SELECT table_name, table_schema
                FROM information_schema.tables
                WHERE table_schema = 'travail' -- Adapter si les tables sont dans un autre schéma
                AND table_type = 'BASE TABLE'
            LOOP
                -- Création de la table de sortie
                EXECUTE 'CREATE TABLE ' || zone_name || '.' || tbl.table_name || ' AS ' ||
                        'SELECT '|| tbl.table_schema || '.' || tbl.table_name || '.* ' || ', ST_Intersection('|| tbl.table_schema || '.' || tbl.table_name || '.geom ' || ' ,temporary.zone_name.geom) as local_geom '|| 
						'FROM ' || tbl.table_schema || '.' || tbl.table_name || ', temporary.zone_name ' || 
						'WHERE ST_Intersects('|| tbl.table_schema || '.' || tbl.table_name || '.'|| 'geom, temporary.zone_name.geom)' || 
						'AND temporary.zone_name.id_zone Like '''||zone_name||''';';
            END LOOP;
        END LOOP;
    END LOOP;
END $$;