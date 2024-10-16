-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque point
CREATE OR REPLACE FUNCTION calculate_street_centroid_bounding_box()
RETURNS VOID AS $$
DECLARE
    record RECORD;
	mot RECORD;
    char_width DOUBLE PRECISION := 3.3 ; -- Approximation de la largeur moyenne d'un caractère en mètres
    text_height DOUBLE PRECISION := 3.5 ; -- Approximation de la hauteur du texte en mètres
    text_length INTEGER;
    bbox_width DOUBLE PRECISION;
    bbox_height DOUBLE PRECISION;
	word_bbox_width DOUBLE PRECISION;
	segment_start_point GEOMETRY;
	segment_end_point GEOMETRY;
	segment_start_temp GEOMETRY;
	segment GEOMETRY;
	segments GEOMETRY[];
	troncon GEOMETRY;
	axis GEOMETRY;
	env GEOMETRY;
	i INT;
	j INT;
	zone_name TEXT;

BEGIN

--On crée la table des rues
DROP TABLE IF EXISTS travail.rueentiere;
CREATE TABLE travail.rueentiere(id serial, text character varying(100), geom geometry(LINESTRING, 2154));


-- Boucle sur les zones du découpage
FOR i IN 0..9 LOOP
     FOR j IN 0..9 LOOP
	 
	 -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_name := 'zone_' || i || '_' || j;
	
	  -- Remplissage de la table qui va stocker les bbox des odonymes
	     EXECUTE 'INSERT INTO travail.rueentiere(text, geom) 
		 SELECT DISTINCT '|| zone_name ||'.tronconderoute.nom_ban_g, ST_Force2D(ST_GeometryN(local_geom, 1)) AS geom
		 FROM '|| zone_name ||'.tronconderoute
		 WHERE ST_GeometryType(geom) = ''ST_MultiLineString'' GROUP BY nom_ban_g, local_geom;';
		 
END LOOP;		 
END LOOP;

 -- Boucle sur chaque point pour calculer le rectangle englobant du texte
    FOR record IN EXECUTE 'SELECT id, text, geom FROM travail.rueentiere WHERE text IS NOT NULL' LOOP
		text_length := char_count(record.text);
		bbox_width := char_width * text_length;
		bbox_height := text_height;
		-- On teste l'orientation de la géométrie
		IF (ST_X(ST_StartPoint(record.geom))>ST_X(ST_EndPoint(record.geom))) 
		THEN troncon := ST_Reverse(record.geom);
		ELSE troncon := record.geom;
		END IF;
		IF (bbox_width + char_width*5 < ST_Length(troncon)) THEN
			 -- Calculer les points de début du segment
       		 segment_start_point := ST_LineInterpolatePoint(troncon, (0.5-(bbox_width / (2*ST_Length(troncon)))));
			 word_bbox_width := 0;
			 
			FOR mot IN SELECT decoupage FROM regexp_split_to_table(record.text, '\s+') AS decoupage LOOP
				segment_start_temp := segment_start_point ;
				word_bbox_width := word_bbox_width + char_width * (1+char_count(mot.decoupage));
				segment_end_point := ST_LineInterpolatePoint(troncon, (0.5+(2*word_bbox_width-bbox_width)/ (2*ST_Length(troncon))));
				segment := ST_MakeLine(segment_start_temp, segment_end_point);
				env := ST_Buffer(segment, bbox_height, 'endcap=flat join=mitre');
				INSERT INTO travail.annotationrue(texte_complet, text_part,bbox,cle_origine) VALUES (record.text, mot.decoupage, env, record.id); 
				segment_start_point := ST_LineInterpolatePoint(troncon, (0.5+(2*(word_bbox_width+char_width/2)-bbox_width)/ (2*ST_Length(troncon))));
				segments := array_append(segments, segment);
			END LOOP;
		
		END IF;
		
		--On complete la table travail.toponymerue
		axis := ST_MakeLine(segments);
		IF ST_Distance(ST_StartPoint(troncon),ST_StartPoint(axis)) < ST_Distance(ST_EndPoint(troncon),ST_StartPoint(axis))
		THEN INSERT INTO travail.toponymerue(texte_complet, cle_origine, geom) VALUES (record.text, record.id, axis); 
		ELSE INSERT INTO travail.toponymerue(texte_complet, cle_origine, geom) VALUES (record.text, record.id, ST_Reverse(axis)); 
		END IF;
		segments := '{}';
	END LOOP;
 
END ;
$$ LANGUAGE plpgsql;

-- Creation d'une table pour stocker les libellés complets et la ligne sur laquelle les afficher
DROP TABLE IF EXISTS travail.toponymerue;
CREATE TABLE travail.toponymerue(id serial PRIMARY KEY, texte_complet character varying(150), cle_origine integer, geom geometry(LINESTRING, 2154));
-- Creation d'une table pour stocker les mots et leurs bbox
DROP TABLE IF EXISTS travail.annotationrue;
CREATE TABLE travail.annotationrue(id serial PRIMARY KEY, texte_complet character varying(150), text_part character varying(25), bbox geometry(POLYGON, 2154), cle_origine integer);
-- Exécution de la fonction pour calculer et mettre à jour les rectangles englobants
SELECT calculate_street_centroid_bounding_box();
