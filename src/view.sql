CREATE OR REPLACE VIEW articoli_disponibili AS
SELECT COD_ART, UNION_HELPER AS tipo_articolo FROM articolo A 
WHERE cod_art NOT IN (
    (SELECT cod_art_det FROM dettaglio_acquisto DA where A.cod_art = DA.cod_art_det)
     UNION
    (SELECT cod_stru FROM strumento_negozio SN, noleggia N where sn.num_serie_stru_neg = n.num_serie_stru_nol AND fine_noleggio > sysdate)
UNION
SELECT cod_art_ec FROM reso
)

CREATE OR REPLACE VIEW strumenti_disponibili AS (
SELECT SN.cod_stru, S.num_serie, S.marca, S.modello, S.peso 
FROM strumento_negozio SN JOIN strumento1 S ON SN.num_serie_stru_neg = S.num_serie
WHERE cod_stru IN (select cod_art from articoli_disponibili));

CREATE OR REPLACE VIEW amplificatori_disponibili AS(
    SELECT * 
    FROM amplificatore A
    WHERE NOT EXISTS (SELECT * FROM dettaglio_acquisto WHERE cod_art_det = A.cod_amp)
);

CREATE OR REPLACE VIEW libri_disponibili AS(  
    SELECT *
    FROM libro L
    WHERE NOT EXISTS (SELECT * FROM dettaglio_acquisto WHERE cod_art_det = L.cod_libro)
);
