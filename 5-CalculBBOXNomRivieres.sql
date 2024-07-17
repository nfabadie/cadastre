-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque point
CREATE OR REPLACE FUNCTION calculate_street_centroid_bounding_box()
RETURNS VOID AS $$
DECLARE
    record RECORD;
	mot RECORD;
    char_width DOUBLE PRECISION := 5.5 ; -- Approximation de la largeur moyenne d'un caractère en mètres
    text_height DOUBLE PRECISION := 5 ; -- Approximation de la hauteur du texte en mètres
    text_length INTEGER;
    bbox_width DOUBLE PRECISION;
    bbox_height DOUBLE PRECISION;
	word_bbox_width DOUBLE PRECISION;
	segment_start_point GEOMETRY;
	segment_end_point GEOMETRY;
	segment_start_temp GEOMETRY;
	segment GEOMETRY;
	troncon GEOMETRY;
	env GEOMETRY;
	i INT;
	j INT;
	zone_name TEXT;

BEGIN

--On crée la table des rues
DROP TABLE IF EXISTS travail.riviere;
CREATE TABLE travail.riviere(id serial, text character varying(100), geom geometry(LINESTRING, 2154));


-- Boucle sur les zones du découpage
FOR i IN 0..9 LOOP
     FOR j IN 0..9 LOOP
	 
	 -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_name := 'zone_' || i || '_' || j;
	
	  -- Remplissage de la table qui va stocker les bbox des odonymes
	     EXECUTE 'INSERT INTO travail.riviere(text, geom) 
		 SELECT DISTINCT '|| zone_name ||'.coursdeau.toponyme, ST_Force2D(local_geom) AS geom
		 FROM '|| zone_name ||'.coursdeau
		 WHERE ST_GeometryType(geom) = ''ST_MultiLineString'' GROUP BY toponyme, local_geom;';
		 
	END LOOP;		 
END LOOP;

 -- Boucle sur chaque point pour calculer le rectangle englobant du texte
    FOR record IN EXECUTE 'SELECT id, text, geom FROM travail.riviere WHERE text IS NOT NULL' LOOP
		text_length := LENGTH(record.text);
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
			 
			FOR mot IN SELECT decoupage FROM regexp_split_to_table(record.text, '\s+|-') AS decoupage LOOP
				segment_start_temp := segment_start_point ;
				word_bbox_width := word_bbox_width + char_width * (1+LENGTH(mot.decoupage));
				segment_end_point := ST_LineInterpolatePoint(troncon, (0.5+(2*word_bbox_width-bbox_width)/ (2*ST_Length(troncon))));
				segment := ST_MakeLine(segment_start_temp, segment_end_point);
				env := ST_Buffer(segment, bbox_height, 'endcap=flat join=mitre');
				INSERT INTO travail.annotationriviere(texte_complet, text_part,bbox,cle_origine) VALUES (record.text, mot.decoupage, env, record.id); 
				segment_start_point := ST_LineInterpolatePoint(troncon, (0.5+(2*(word_bbox_width+char_width)-bbox_width)/ (2*ST_Length(troncon))));
			END LOOP;
		
		END IF;
		
	END LOOP;
 
END ;
$$ LANGUAGE plpgsql;

-- Creation d'une table pour stocker les mots et leurs bbox
DROP TABLE IF EXISTS travail.annotationriviere;
CREATE TABLE travail.annotationriviere(id serial PRIMARY KEY, texte_complet character varying(150), text_part character varying(25), bbox geometry(POLYGON, 2154), cle_origine integer);
-- Exécution de la fonction pour calculer et mettre à jour les rectangles englobants
SELECT calculate_street_centroid_bounding_box();
