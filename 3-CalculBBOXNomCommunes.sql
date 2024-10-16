-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque point
CREATE OR REPLACE FUNCTION calculate_polygon_centroid_bounding_box()
RETURNS VOID AS $$
DECLARE
    record RECORD;
	mot RECORD;
    char_width DOUBLE PRECISION := 16; -- Approximation de la largeur moyenne d'un caractère en mètres
    text_height DOUBLE PRECISION := 14; -- Approximation de la hauteur du texte en mètres
    text_length INTEGER;
    bbox_width DOUBLE PRECISION;
    bbox_height DOUBLE PRECISION;
	Xmin DOUBLE PRECISION;
	Ymin DOUBLE PRECISION;
	Xmax DOUBLE PRECISION;
	Ymax DOUBLE PRECISION;
	Xstart DOUBLE PRECISION;
	env GEOMETRY;
	zone_name TEXT;

BEGIN

     -- Boucles sur les zones du découpage
     FOR i IN 0..9 LOOP
     FOR j IN 0..9 LOOP
	 
	 -- Nom de la zone (peut être ajusté selon le format souhaité)
            zone_name := 'zone_' || i || '_' || j;
			
    -- Boucle sur chaque point pour calculer le rectangle englobant du texte
    FOR record IN EXECUTE 'SELECT f.id, f.nom_com as text, ST_X(ST_Centroid(z.geom)) AS x, ST_Y(ST_Centroid(z.geom)) AS y FROM '|| zone_name ||'.feuille as f, temporary.zone_name as z WHERE z.id_zone = '''||zone_name||''' AND ST_Area(f.geom) = (SELECT Max(ST_Area(f2.geom)) FROM '|| zone_name ||'.feuille as f2);' LOOP
			text_length := char_count(record.text);
			bbox_width := char_width * text_length;
			bbox_height := text_height;
			Xstart := record.x - bbox_width/2;
			Ymin := record.y - bbox_height/2;
			Ymax := record.y + bbox_height/2;
		FOR mot IN SELECT decoupage FROM regexp_split_to_table(record.text, '\s+') AS decoupage LOOP
			Xmin := Xstart ;
			Xmax := Xmin + char_width * char_count(mot.decoupage);
			env := ST_MakeEnvelope(Xmin, Ymin, Xmax, Ymax, 2154);
			INSERT INTO travail.annotationcommune(texte_complet, text_part,bbox,cle_origine) VALUES (record.text, mot.decoupage, env, record.id); 
			Xstart := Xmax + char_width;
		END LOOP;
    END LOOP;
	
	-- Fin des boucles sur les zones du découpage
	END LOOP;
	END LOOP;
	
END;
$$ LANGUAGE plpgsql;

-- Creation d'une table pour stocker les mots et leurs bbox
DROP TABLE IF EXISTS travail.annotationcommune;
CREATE TABLE travail.annotationcommune(id serial PRIMARY KEY, texte_complet character varying (100), text_part character varying(50), bbox geometry(POLYGON, 2154), cle_origine integer);
-- Exécution de la fonction pour calculer et mettre à jour les rectangles englobants
SELECT calculate_polygon_centroid_bounding_box();
