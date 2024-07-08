-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque point
CREATE OR REPLACE FUNCTION calculate_river_centroid_bounding_box()
RETURNS VOID AS $$
DECLARE
    record RECORD;
    char_width DOUBLE PRECISION := 4.5 ; -- Approximation de la largeur moyenne d'un caractère en mètres
    text_height DOUBLE PRECISION := 8 ; -- Approximation de la hauteur du texte en mètres
    text_length INTEGER;
    bbox_width DOUBLE PRECISION;
    bbox_height DOUBLE PRECISION;
	segment_start_point GEOMETRY;
	segment_end_point GEOMETRY;
	segment GEOMETRY;
	current_text TEXT;
	i INT;
	j INT;
	zone_name TEXT;

BEGIN

--On crée la table des rues
DROP TABLE travail.riviere;
CREATE TABLE travail.riviere(text character varying(100), geom geometry(LINESTRING, 2154), bbox geometry(GEOMETRY, 2154));


-- Boucle sur les zones du découpage
FOR i IN 0..9 LOOP
     FOR j IN 0..9 LOOP
	 
	 -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_name := 'zone_' || i || '_' || j;
	
	  -- Remplissage de la table qu va stocker les bbox des odonymes
	     EXECUTE 'INSERT INTO travail.riviere(text, geom) 
		      (SELECT DISTINCT coursdeau.toponyme as text, (ST_DUMP(ST_FORCE2D(ST_UNION(coursdeau.local_geom)))).geom as geom 
	 	       FROM '||zone_name||'.coursdeau 
   		       GROUP BY coursdeau.toponyme);';

    -- Boucle sur chaque point pour calculer le rectangle englobant du texte
    FOR record IN EXECUTE 'SELECT text, geom FROM travail.riviere WHERE bbox IS NULL' LOOP
		current_text := record.text;
	    RAISE NOTICE 'On traite la riviere : %', current_text;
        text_length := LENGTH(record.text);
        bbox_width := char_width * text_length;
        bbox_height := text_height;

        -- On s'assure que le tronçon de rue est suffisamment long
		IF (bbox_width < ST_Length(record.geom)) THEN
		
		    -- Calculer les points de début et de fin du segment
        	segment_start_point := ST_LineInterpolatePoint(record.geom, (0.5-(bbox_width / (2*ST_Length(record.geom)))));
        	segment_end_point := ST_LineInterpolatePoint(record.geom, (0.5+(bbox_width / (2*ST_Length(record.geom)))));
			-- Créer un segment de polyligne de longueur spécifiée
            segment := ST_MakeLine(segment_start_point, segment_end_point);
			-- Mise à jour de la table avec les coordonnées du rectangle englobant
			EXECUTE 'UPDATE travail.riviere 
		 	SET bbox = (ST_Buffer($1, $2, ''endcap=flat join=mitre''))
            WHERE bbox IS NULL AND text= $3;'
			USING segment, bbox_height, current_text;
			
        END IF;
		
    END LOOP;
		 
END LOOP;
		 
END LOOP;
 
END ;
$$ LANGUAGE plpgsql;


-- Exécution de la fonction pour calculer et mettre à jour les rectangles englobants
SELECT calculate_river_centroid_bounding_box();