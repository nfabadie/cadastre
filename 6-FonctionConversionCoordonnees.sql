-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque rue
CREATE OR REPLACE FUNCTION coord_carto_to_image(X DOUBLE PRECISION, Y DOUBLE PRECISION, X0 DOUBLE PRECISION, Y0 DOUBLE PRECISION)
RETURNS text AS $$
DECLARE
    X_IMG DOUBLE PRECISION; 
    Y_IMG DOUBLE PRECISION;
	coord_img TEXT;
    
BEGIN

   X_IMG := (X - X0)/0.331 ;
   Y_IMG := (Y0 - Y)/0.331 ;
   coord_img := 'POINT('||X_IMG ::text ||' '||Y_IMG::text||')';
   RETURN coord_img;
   
END;
$$ LANGUAGE plpgsql;

