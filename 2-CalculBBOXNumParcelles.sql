-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque point
CREATE OR REPLACE FUNCTION calculate_parcel_number_bounding_box()
RETURNS VOID AS $$
DECLARE
    record RECORD;
    char_width DOUBLE PRECISION := 2.5; -- Approximation de la largeur moyenne d'un caractère en mètres
    text_height DOUBLE PRECISION := 3.5; -- Approximation de la hauteur du texte en mètres
    text_length INTEGER;
    bbox_width DOUBLE PRECISION;
    bbox_height DOUBLE PRECISION;

BEGIN
    -- Boucle sur chaque point pour calculer le rectangle englobant du texte
    FOR record IN SELECT id, ST_X(geom) AS x, ST_Y(geom) AS y, numero as text FROM travail.localisant LOOP
        text_length := LENGTH(record.text);
        bbox_width := char_width * text_length;
        bbox_height := text_height;
        
        
        -- Mise à jour de la table avec les coordonnées du rectangle englobant
        UPDATE travail.localisant
        SET bbox = ST_MakeEnvelope(record.x - bbox_width/2, record.y - bbox_height/2, record.x + bbox_width/2, record.y + bbox_height/2, ST_SRID(geom))
        WHERE id = record.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Ajout de la colonne bbox
ALTER TABLE travail.localisant DROP COLUMN bbox;
ALTER TABLE travail.localisant ADD COLUMN bbox geometry;
-- Exécution de la fonction pour calculer et mettre à jour les rectangles englobants
SELECT calculate_parcel_number_bounding_box();