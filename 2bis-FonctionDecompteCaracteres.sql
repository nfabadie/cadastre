-- Création d'une fonction PL/pgSQL pour calculer le rectangle englobant du texte associé à chaque rue
CREATE OR REPLACE FUNCTION char_count(texte text)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    text_length DOUBLE PRECISION; 
	small_characters INTEGER;
	big_characters INTEGER; 
    
BEGIN

	-- On compte les caractères "courts" (les i, les l, les t, les r, les ')
	small_characters := length(texte) - length(regexp_replace(texte, 'i|l|t|r|''', ''));
	-- On compte les caractères "longs" (les majuscules)
	big_characters := length(texte) - length(regexp_replace(texte, '[A-Z]', ''));
	-- On calcule le nombre de charactères du texte
	text_length := length(texte) - (small_characters+big_characters) + 0.5*small_characters + 1.5*big_characters;
															
   RETURN text_length;
   
END;
$$ LANGUAGE plpgsql;
