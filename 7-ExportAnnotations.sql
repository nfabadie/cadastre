DO $$ 
DECLARE
    i INT;
    j INT;
	x_min DOUBLE PRECISION;
	y_max DOUBLE PRECISION;
    zone_val TEXT;

BEGIN
DROP TABLE annotations;  
CREATE TABLE annotations(id serial PRIMARY KEY, id_zone character varying(10), nature character varying (20), cle_origine integer, texte_complet character varying(150), texte character varying(25), xmin_ymin character varying(50), xmin_ymax character varying(50), xmax_ymax character varying(50), xmax_ymin character varying(50));	


    -- Boucle pour générer les zones
    FOR i IN 0..9 LOOP
        FOR j IN 0..9 LOOP

            -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_val := 'zone_' || i || '_' || j;
			
			-- Coord du point au nord est de la zone)
			x_min := (SELECT ST_XMin(temporary.zone_name.geom) FROM temporary.zone_name WHERE temporary.zone_name.id_zone like zone_val);
			y_max := (SELECT ST_YMax(temporary.zone_name.geom) FROM temporary.zone_name WHERE temporary.zone_name.id_zone like zone_val);
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (id_zone, cle_origine, texte_complet, texte, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT temporary.zone_name.id_zone, travail.localisant.id, numero, numero, coord_carto_to_image(ST_XMin(travail.localisant.bbox), ST_YMax(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.localisant.bbox), ST_YMin(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.localisant.bbox), ST_YMin(travail.localisant.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.localisant.bbox), ST_YMax(travail.localisant.bbox),'||x_min||', '||y_max||')
			FROM travail.localisant, temporary.zone_name
			WHERE st_within(travail.localisant.geom, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''parcelle'' WHERE annotations.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (id_zone, cle_origine, texte_complet, texte, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT temporary.zone_name.id_zone, travail.annotationcommune.cle_origine, travail.annotationcommune.texte_complet, travail.annotationcommune.text_part, coord_carto_to_image(ST_XMin(travail.annotationcommune.bbox), ST_YMax(travail.annotationcommune.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.annotationcommune.bbox), ST_YMin(travail.annotationcommune.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationcommune.bbox), ST_YMin(travail.annotationcommune.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationcommune.bbox), ST_YMax(travail.annotationcommune.bbox),'||x_min||', '||y_max||')
			FROM travail.annotationcommune, temporary.zone_name
			WHERE st_within(travail.annotationcommune.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''commune'' WHERE annotations.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (id_zone, cle_origine, texte_complet, texte, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT temporary.zone_name.id_zone, travail.annotationrue.cle_origine, travail.annotationrue.texte_complet, travail.annotationrue.text_part, coord_carto_to_image(ST_XMin(travail.annotationrue.bbox), ST_YMax(travail.annotationrue.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.annotationrue.bbox), ST_YMin(travail.annotationrue.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationrue.bbox), ST_YMin(travail.annotationrue.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationrue.bbox), ST_YMax(travail.annotationrue.bbox),'||x_min||', '||y_max||')
			FROM travail.annotationrue, temporary.zone_name
			WHERE st_within(travail.annotationrue.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''rue'' WHERE annotations.nature IS NULL;';
			
			-- On récupère les textes à annoter et leur bbox en pixels
			EXECUTE 'INSERT INTO annotations (id_zone, cle_origine, texte_complet, texte, xmin_ymin, xmin_ymax, xmax_ymax, xmax_ymin)
			SELECT DISTINCT temporary.zone_name.id_zone, travail.annotationriviere.cle_origine, travail.annotationriviere.texte_complet, travail.annotationriviere.text_part, coord_carto_to_image(ST_XMin(travail.annotationriviere.bbox), ST_YMax(travail.annotationriviere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMin(travail.annotationriviere.bbox), ST_YMin(travail.annotationriviere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationriviere.bbox), ST_YMin(travail.annotationriviere.bbox), '||x_min||', '||y_max||'), coord_carto_to_image(ST_XMax(travail.annotationriviere.bbox), ST_YMax(travail.annotationriviere.bbox),'||x_min||', '||y_max||')
			FROM travail.annotationriviere, temporary.zone_name
			WHERE st_within(travail.annotationriviere.bbox, temporary.zone_name.geom) and temporary.zone_name.id_zone like '''||zone_val||''';';
			
			-- On complète la table pour préciser la nature des textes annotés
			EXECUTE 'UPDATE annotations SET nature = ''riviere'' WHERE annotations.nature IS NULL;';
			
        END LOOP;
    END LOOP;
END $$;
