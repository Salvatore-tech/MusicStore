--***** STUDENTI *****

  -- Studenti che si sono iscritti a più di 2 corsi (cerca l'allievo che è iscritto a più corsi)
  SELECT EI.cf_allievo_i, COUNT(*) AS no_corsi_iscritto
  FROM corso C, e_iscritto EI
  WHERE C.cod_corso = ei.cod_corso_i
  GROUP BY EI.cf_allievo_i
  HAVING COUNT(*) > 2;

  -- Recupera i dati anagrafici delle studentess iscritte a più di 2 corsi
  SELECT * FROM persona1 WHERE sesso = UPPER('F') AND cf = ANY(
      SELECT EI.cf_allievo_i
      FROM corso C, e_iscritto EI
      WHERE C.cod_corso = ei.cod_corso_i
      GROUP BY EI.cf_allievo_i
      HAVING COUNT(*) > 2
  );

  -- Numero di lezioni frequentate dagli studenti
  SELECT a.cf_allievo, COUNT(*) AS lezioni_seguite
  FROM frequenta F, allievo A
  WHERE F.cf_allievo_f = A.cf_allievo
  GROUP BY a.cf_allievo;

--***** IMPIEGATI *****
-- Addetti vendite: 46201, 44195, 33089

  -- Primo impiegato ASsunto
  SELECT  cf_imp, MIN(data_ASsunzione) FROM impiegato GROUP BY cf_imp;

  -- Visualizzare per ogni supervisore il numero di addetti supervisionati
  SELECT cod_tess_sup, COUNT(*) AS no_addetti
  FROM addetto_reparto
  WHERE cod_tess_sup IS NOT NULL
  GROUP BY cod_tess_sup;

  -- No corsi tenuti dagli insegnanti
  SELECT i.cod_tess_ins, count(*) AS no_corsi
  FROM insegnante I, corso C
  WHERE I.cod_tess_ins = c.cod_tess_ins_corso
  GROUP BY i.cod_tess_ins;

  -- Strumenti per i quali l'addetto deve ancora creare l'annuncio di vendita (hurry up!!!)
  SELECT * FROM strumento_usato S WHERE NOT exists (SELECT * FROM annuncio WHERE S.num_serie_stru_usato = num_serie_stru_ann);

  -- Visualizza gli addetti ed il no_vendite che hanno registrato
  SELECT cod_tess_add_vendita, count(*) AS no_vendite FROM acquisto  GROUP BY cod_tess_add_vendita ORDER BY no_vendite DESC;

  -- Seleziona tutti i dettagli relativi agli acquisti registrati dall'addetto
  SELECT * FROM acquisto ACQ, articolo A JOIN dettaglio_acquisto DA ON A.cod_art=DA.cod_art_det  WHERE ACQ.cod_scon = DA.cod_scon_det AND  cod_tess_add_vendita = 44195;

  -- Seleziona no_vendite e fatturato dell'addetto
  SELECT cod_tess_add_vendita, sum(prezzo), count(*)
  FROM acquisto ACQ, articolo A JOIN dettaglio_acquisto DA ON A.cod_art=DA.cod_art_det
  WHERE ACQ.cod_scon = DA.cod_scon_det AND cod_tess_add_vendita = 44195
  GROUP BY cod_tess_add_vendita;

  -- Seleziono gli addetti che hanno effettuato più vendite nel dato mese, il numero di vendite ed il relativo fatturato
  SELECT cod_tess_add_vendita, sum(prezzo), count(*)
  FROM acquisto ACQ, articolo A JOIN dettaglio_acquisto DA ON A.cod_art=DA.cod_art_det
  WHERE ACQ.cod_scon = DA.cod_scon_det
  AND to_char(data_a, 'mon') = lower('giu') AND extract(year FROM data_a) = 2020
  GROUP BY cod_tess_add_vendita ORDER BY count(*) DESC;

  -- Liutaio con meno riparazioni a carico
  SELECT * FROM (SELECT cod_tess_liu_rip, COUNT(*) AS occ FROM riparazione GROUP BY cod_tess_liu_rip ORDER BY occ ASc) WHERE rownum = 1;


--***** VENDITE/RESI/CONSEGNE *****

  -- Visualizza acquisti singoli
  SELECT da.cod_scon_det
  FROM dettaglio_acquisto DA, acquisto A
  WHERE A.cod_scon = DA.cod_scon_det
  GROUP BY da.cod_scon_det
  HAVING count(*) = 1;

  -- Visualizza tutti i dettagli relativi gli acquisti singoli
  SELECT * FROM acquisto A WHERE cod_scon IN(
      SELECT da.cod_scon_det
      FROM dettaglio_acquisto DA
      WHERE A.cod_scon = DA.cod_scon_det
      GROUP BY da.cod_scon_det
      HAVING count(*) = 1
  );

  -- Visualizza il costo totale dato il codice scontrino
  SELECT sum(A.prezzo) FROM dettaglio_acquisto DA, articolo A WHERE A.cod_art = DA.cod_art_det AND DA.cod_scon_det = 'yha614vgwY';

  -- Numero di acquisti spediti al dato cliente
  SELECT cf_acq_cons, count(*) FROM consegna
  WHERE cf_acq_cons = 'ADRFIL04O77O042N'
  GROUP BY cf_acq_cons;

  -- Acquisti contenenti articoli multipli, no_articoli acquistati e totale
  SELECT cod_scon_det, count(*) AS no_articoli_acquistati, sum(prezzo) AS costo_totale
  FROM dettaglio_acquisto, articolo WHERE articolo.cod_art = dettaglio_acquisto.cod_art_det
  GROUP BY cod_scon_det HAVING count(*) > 2;

  -- Visualizza gli acquisti spediti con più di 2 articoli in ordine decrescente
  SELECT * FROM (
    SELECT cod_scon_det, count(*) AS no_articoli_acquistati FROM dettaglio_acquisto DA, consegna C WHERE DA.cod_scon_det = C.cod_scon_cons
    GROUP BY cod_scon_det
    HAVING count(*)>1)
  order by no_articoli_acquistati desc;

  -- Conta il numero di strumenti che l'acquirente deve restituire in data odierna
  SELECT COUNT(*) FROM noleggia WHERE cf_acq_nol = 'BEALEV72P41G636P' AND (fine_noleggio) > sysdate; -- '30-NOV-19' -> 2 strumenti


--***** MISC *****

  -- Testing multiple insertion (wrong data)
  insert into biglietto2(tipo_biglietto) SELECT nome FROM persona1 WHERE rownum <= 3;

    -- DATE --
    -- Rappresentazione std del formato data
    SELECT to_date(sysdate, 'DD-Mon-YYYY') FROM dual;

    -- 3 giorni fa
    SELECT TRUNC(SYSDATE - 3) FROM dual;

    -- Rappresentazione short mese corrente
    SELECT to_char(sysdate, 'mon') FROM dual;

     -- Rappresentazione long mese corrente
    SELECT to_char(add_months(sysdate, -1), 'month') FROM dual;

    -- Mese precedente e anno
    SELECT to_char(add_months(sysdate, -1), 'mon/yyyy') FROM dual;

    -- Mese prossimo (number)
    SELECT EXTRACT(MONTH FROM sysdate)+1 FROM dual;

    -- Anno corrente
    SELECT extract(year FROM to_date(sysdate)) FROM dual;

    -- No anni tra due date
    SELECT ROUND(months_between(sysdate,'20-APR-2005')/12) FROM dual;

    -- No ore tra 2 date
    SELECT (ROUND(to_number(to_date('14-AGO-20') - sysdate)*24)) FROM dual;

    -- Acquisti di marzo
    SELECT * FROM acquisto WHERE to_char (data_a, 'mon') = 'mar';
