/*Exemple de code pour définir les styles*/
-- Ajout d'une colonne style à la grille
ALTER TABLE travail.selected_grid ADD COLUMN style character varying(20);

-- Création d'une table styles avec une colonne id et une description
CREATE TABLE styles (idstyle character varying (20), description character varying (150));

-- Insertion des styles dans la table des styles
INSERT INTO styles (idstyle, description) VALUES ('style1', 'Test');
INSERT INTO styles (idstyle, description) VALUES ('style2', 'Test');
INSERT INTO styles (idstyle, description) VALUES ('style3', 'Test');

-- Mise à jour de la colonne style dans la table de la grille "selected_grid"
UPDATE travail.selected_grid
SET style = CASE
    WHEN id BETWEEN 1 AND 3000 THEN 'style1'
    WHEN id BETWEEN 3001 AND 6000 THEN 'style2'
    WHEN id BETWEEN 6001 AND 9000 THEN 'style3'
    ELSE NULL  -- Optionally handle IDs outside of the expected range
END;