DO $$ 
DECLARE
    i INT;
    j INT;
	x_min DOUBLE PRECISION;
	y_max DOUBLE PRECISION;
    zone_val TEXT;
	l INT;
	s INT;
	rec_rue RECORD;
	rec_riv RECORD;
	coords_rue GEOMETRY;
	coords_riv GEOMETRY;
	x_riv DOUBLE PRECISION;
	y_riv DOUBLE PRECISION;
	x_rue DOUBLE PRECISION;
	y_rue DOUBLE PRECISION;

BEGIN
DROP TABLE IF EXISTS annotations_tab_name;  
CREATE TABLE annotations_tab_name(id serial PRIMARY KEY, id_zone character varying(10), nature character varying (20), cle_origine integer, texte_complet character varying(150), cle_text_part integer, texte character varying(50), x1_y1 character varying(50), x2_y2 character varying(50), x3_y3 character varying(50), x4_y4 character varying(50));	


    -- Boucle pour générer les zones
    FOR i IN 0..9 LOOP
        FOR j IN 0..9 LOOP

            -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_val := 'zone_' || i || '_' || j;
			
			-- Coord du point au nord est de la zone)
			x_min := (SELECT ST_XMin(temporary.zone_name.geom) FROM temporary.zone_name WHERE temporary.zone_name.id_zone like zone_val);
			y_max := (SELECT ST_YMax(temporary.zone_name.geom) FROM temporary.zone_name WHERE temporary.zone_name.id_zone like zone_val);
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations_tab_name (id_zone, cle_origine, texte_complet, cle_text_part, texte, x1_y1, x2_y2, x3_y3, x4_y4)
			SELECT DISTINCT temporary.zone_name.id_zone, travail.localisant.id, numero, travail.localisant.id, numero, coord_carto_to_image(ST_XMin(travail.localisant.bbox), ST_YMax(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.localisant.bbox), ST_YMin(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.localisant.bbox), ST_YMin(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.localisant.bbox), ST_YMax(travail.localisant.bbox),'||x_min||', '||y_max||')
			FROM travail.localisant, temporary.zone_name
			WHERE st_within(travail.localisant.geom, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations_tab_name SET nature = ''parcelle'' WHERE annotations_tab_name.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations_tab_name (id_zone, cle_origine, texte_complet, cle_text_part, texte,  x1_y1, x2_y2, x3_y3, x4_y4)
			SELECT DISTINCT temporary.zone_name.id_zone, travail.annotationcommune.cle_origine, travail.annotationcommune.texte_complet, travail.annotationcommune.id, travail.annotationcommune.text_part, coord_carto_to_image(ST_XMin(travail.annotationcommune.bbox), ST_YMax(travail.annotationcommune.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.annotationcommune.bbox), ST_YMin(travail.annotationcommune.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationcommune.bbox), ST_YMin(travail.annotationcommune.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationcommune.bbox), ST_YMax(travail.annotationcommune.bbox),'||x_min||', '||y_max||')
			FROM travail.annotationcommune, temporary.zone_name
			WHERE st_within(travail.annotationcommune.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations_tab_name SET nature = ''commune'' WHERE annotations_tab_name.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations_tab_name (id_zone, cle_origine, texte_complet, cle_text_part, texte) SELECT DISTINCT temporary.zone_name.id_zone as idz, travail.annotationrue.cle_origine, travail.annotationrue.texte_complet, travail.annotationrue.id, travail.annotationrue.text_part
								FROM travail.annotationrue, temporary.zone_name
								WHERE st_within(travail.annotationrue.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			FOR rec_rue IN EXECUTE 'SELECT DISTINCT id as cle_text_part, cle_origine, ST_ExteriorRing(travail.annotationrue.bbox) AS exterior
								FROM travail.annotationrue, temporary.zone_name
								WHERE st_within(travail.annotationrue.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';' LOOP 
        		s := 1;
        		coords_rue := rec_rue.exterior;
        		FOR s IN 1 .. 4 LOOP
						x_rue := ST_X(ST_PointN(coords_rue,s));
						y_rue := ST_Y(ST_PointN(coords_rue,s));
						EXECUTE 'UPDATE annotations_tab_name SET x'||s||'_y'||s||'= coord_carto_to_image('||x_rue||', '||y_rue||', '||x_min||', '||y_max||') WHERE cle_origine = '''||rec_rue.cle_origine||''' AND cle_text_part = '''||rec_rue.cle_text_part||''';';
        		END LOOP;
   			END LOOP; 
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations_tab_name SET nature = ''rue'' WHERE annotations_tab_name.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en 
			EXECUTE 'INSERT INTO annotations_tab_name (id_zone, cle_origine, texte_complet, cle_text_part, texte) SELECT DISTINCT temporary.zone_name.id_zone as idz, travail.annotationriviere.cle_origine, travail.annotationriviere.texte_complet, travail.annotationriviere.id, travail.annotationriviere.text_part
								FROM travail.annotationriviere, temporary.zone_name
								WHERE st_within(travail.annotationriviere.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			FOR rec_riv IN EXECUTE 'SELECT DISTINCT cle_origine, id as cle_text_part, ST_ExteriorRing(travail.annotationriviere.bbox) AS exterior
								FROM travail.annotationriviere, temporary.zone_name
								WHERE st_within(travail.annotationriviere.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';' LOOP 
        		s := 1;
        		coords_riv := rec_riv.exterior;
        		FOR s IN 1 .. 4 LOOP
						x_riv := ST_X(ST_PointN(coords_riv,s));
						y_riv := ST_Y(ST_PointN(coords_riv,s));
						EXECUTE 'UPDATE annotations_tab_name SET x'||s||'_y'||s||'= coord_carto_to_image('||x_riv||', '||y_riv||', '||x_min||', '||y_max||') WHERE cle_origine = '''||rec_riv.cle_origine||''' AND cle_text_part ='||rec_riv.cle_text_part||';';
        		END LOOP;
   			END LOOP; 
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations_tab_name SET nature = ''riviere'' WHERE annotations_tab_name.nature IS NULL;';

			
        END LOOP;
    END LOOP;
END $$;
