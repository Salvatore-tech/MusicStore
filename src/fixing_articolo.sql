-- Changes to union type --
-- Adding a 'dummy' field (union_helper) to know which items are "amplificatore", "strumenti_negozio" or "libro"
ALTER TABLE articolo
ADD union_helper CHAR(1);

ALTER TABLE articolo
ADD CONSTRAINT union_ok CHECK(INITCAP(union_helper IN ('S', 'A', 'L');
 
UPDATE articolo SET union_helper = 'S' WHERE articolo.cod_art IN (SELECT cod_art
    FROM ARTICOLO A, STRUMENTO_NEGOZIO S
    WHERE A.cod_art = S.cod_stru
);

UPDATE articolo SET union_helper = 'A' WHERE articolo.cod_art IN (SELECT cod_art
    FROM articolo A, amplificatore AMP
    WHERE A.cod_art = AMP.cod_amp
);

UPDATE articolo SET union_helper = 'L' WHERE articolo.cod_art IN (SELECT cod_art
    FROM articolo A, libro L
    WHERE A.cod_art = L.cod_libro
);

-- Testing if the values of articolo.union_helper are as expected
SELECT * FROM amplificatore WHERE cod_amp = 66682;
SELECT * FROM strumento_negozio WHERE cod_stru = 63665;
SELECT * FROM libro WHERE cod_libro = 65235;
-- end change union type --


-- Adding prices into articolo
ALTER TABLE articolo
ADD prezzo NUMBER(5,2);

-- Fetching prices that previusly are on strumento_negozio, amplificatore, libro
UPDATE articolo
SET prezzo = (SELECT prezzo FROM amplificatore WHERE amplificatore.cod_amp = articolo.cod_art)
WHERE EXISTS (SELECT cod_amp FROM amplificatore WHERE articolo.cod_art = amplificatore.cod_amp);

UPDATE articolo
SET prezzo = (SELECT prezzo FROM libro WHERE libro.cod_libro = articolo.cod_art)
WHERE EXISTS (SELECT cod_libro FROM libro WHERE articolo.cod_art = libro.cod_libro);

UPDATE articolo
SET prezzo = (SELECT prezzo FROM strumento1 S, strumento_negozio SN WHERE s.num_serie = SN.num_serie_stru_neg and articolo.cod_art = sn.cod_stru)
WHERE EXISTS (SELECT cod_stru FROM strumento_negozio WHERE articolo.cod_art = strumento_negozio.cod_stru);


-- Assertion, should return null
select * from strumento_negozio S, amplificatore A where S.cod_stru = A.cod_amp;
select cod_libro from libro 
intersect 
select cod_stru from strumento_negozio
intersect 
select cod_amp from amplificatore;

