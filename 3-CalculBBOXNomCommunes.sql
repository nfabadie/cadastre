-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque point
CREATE OR REPLACE FUNCTION calculate_polygon_centroid_bounding_box()
RETURNS VOID AS $$
DECLARE
    record RECORD;
	mot RECORD;
    char_width DOUBLE PRECISION := 7; -- Approximation de la largeur moyenne d'un caractère en mètres
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

BEGIN
    -- Boucle sur chaque point pour calculer le rectangle englobant du texte
    FOR record IN SELECT id, ST_X(ST_Centroid(geom)) AS x, ST_Y(ST_Centroid(geom)) AS y, nom_com as text FROM travail.feuille LOOP
			text_length := LENGTH(record.text);
			bbox_width := char_width * text_length;
			bbox_height := text_height;
			Xstart := record.x - bbox_width/2;
			Ymin := record.y - bbox_height/2;
			Ymax := record.y + bbox_height/2;
		FOR mot IN SELECT decoupage FROM regexp_split_to_table(record.text, '\s+|-') AS decoupage LOOP
			Xmin := Xstart ;
			Xmax := Xmin + char_width * LENGTH(mot.decoupage);
			env := ST_MakeEnvelope(Xmin, Ymin, Xmax, Ymax, 2154);
			INSERT INTO travail.annotationcommune(texte_complet, text_part,bbox,cle_origine) VALUES (record.text, mot.decoupage, env, record.id); 
			Xstart := Xmax + char_width;
		END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Creation d'une table pour stocker les mots et leurs bbox
DROP TABLE IF EXISTS travail.annotationcommune;
CREATE TABLE travail.annotationcommune(id serial PRIMARY KEY, texte_complet character varying (70), text_part character varying(25), bbox geometry(POLYGON, 2154), cle_origine integer);
-- Exécution de la fonction pour calculer et mettre à jour les rectangles englobants
SELECT calculate_polygon_centroid_bounding_box();
