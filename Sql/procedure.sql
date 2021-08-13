-- Calcolo il totale relativo all'acquisto ricevuto in input
create or replace PROCEDURE TOTALE_ACQUISTO (COD_SCONTRINO IN VARCHAR2 , TOTALE OUT NUMBER ) AS 
    BEGIN
    select sum(A.prezzo) INTO totale from dettaglio_acquisto DA, articolo A 
    where A.cod_art = DA.cod_art_det and DA.cod_scon_det = cod_scontrino;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'Codice scontrino errato!');
END TOTALE_ACQUISTO;

/*
Questa procedura riceve in input il numero di articoli acquistati, la data d'acquisto e la modalità di pagamento.
Successivamente si genera pseudo-casualmente la stringa che identifica lo scontrino e si crea l'acquisto associando il codice scontrino al numero di articoli
ricevuti in input. Una prima eccezione controlla che il numero di articoli da acquistare è minore di quelli disponibili per la vendita e
una seconda controlla se è consentito il pagamento a rate.
Come da requisiti, il pagamento a rate è consentito solo per importi superiori a 350 euro (una procedura ausiliaria calcola il totale relativo l'acquisto appena generato).
*/
create or replace PROCEDURE ACQUISTO_AUTOMATICO 
(NO_ARTICOLI IN NUMBER , DATA_ACQUISTO IN DATE , MOD_PAGAMENTO IN VARCHAR2, CODICE_SCONTRINO OUT VARCHAR2) AS
    flag_rigenera NUMBER := 1; -- Rigenera il codice scontrino
    prezzo_totale NUMBER := 0;
    conta NUMBER := 0;
    payment_refused EXCEPTION;
    not_available EXCEPTION;
    BEGIN
    WHILE (flag_rigenera <> 0) -- Rigenera finchè il codice scontrino è univoco
    LOOP
        SELECT dbms_random.string('A', 10) INTO codice_scontrino FROM dual; -- check cod_scon is unique
        SELECT count(*) INTO flag_rigenera FROM acquisto WHERE cod_scon = codice_scontrino; 
    END LOOP;
    SELECT COUNT(*) INTO conta FROM articoli_disponibili;
    IF (conta < no_articoli) THEN
        RAISE not_available;
    END IF;
    INSERT INTO acquisto VALUES(codice_scontrino, mod_pagamento, data_acquisto); 
    -- Multiple insertion, cursor will be deprecated
    INSERT INTO dettaglio_acquisto SELECT codice_scontrino, cod_art FROM articoli_disponibili WHERE rownum <= no_articoli;
    totale_acquisto(codice_scontrino, prezzo_totale); -- Calcola il totale relativo all'acquisto effettuato
    IF (mod_pagamento = lower('rate') AND prezzo_totale < 350) THEN-- Controlla se è possibile il pagamento a rate
        RAISE payment_refused;
    END IF;
    COMMIT;
    EXCEPTION
    WHEN not_available THEN
        RAISE_APPLICATION_ERROR(-20040, '1+ articoli non più disponibili');
    WHEN payment_refused THEN
        RAISE_APPLICATION_ERROR(-20020, 'Pagamento a rate consentito solo per acquisti superiori a 350 euro!');
END ACQUISTO_AUTOMATICO;

/*
Tale procedura crea innanzitutto l'acquisto ricevendo in input il cf dell'acquirente, numero di articoli da acquistare, data e modalità di pagamento.
Successivamente genera una data di consegna valida, ovvero successiva a quella di pagamento dell'acquisto fino ad un massimo di 15 giorni (in tal modo è prevista la
possibilità di una consegna in ritardo). Se il cliente non è registrato, ovvero non ha già effettuato acquisti in passato, è prevista un'eccezione.
*/
create or replace PROCEDURE CONSEGNA_ACQUISTO 
(CF_ACQUIRENTE IN VARCHAR2 , NO_ARTICOLI IN NUMBER , MOD_PAGAMENTO IN VARCHAR2, DATA_PAGAMENTO IN DATE) AS 
    cod_scontrino acquisto.cod_scon%TYPE;
    codice_tracciamento consegna.cod_tracc%TYPE;
    data_consegna DATE;
    cliente_registrato CHAR(16);
    flag_rigenera NUMBER := 1; -- Rigenera il codice consegna 
BEGIN
    SELECT data_pagamento + floor(dbms_random.value(3, 15)) INTO data_consegna from dual;
    acquisto_automatico(no_articoli, data_pagamento, mod_pagamento, cod_scontrino); -- Genera l'acquisto
    SELECT cf_acq INTO cliente_registrato FROM ACQUIRENTE  WHERE cf_acq = cf_acquirente; -- Può provocare no_data_found        
    WHILE (flag_rigenera <> 0) -- Rigenera finchè il codice scontrino è univoco
    LOOP
        SELECT dbms_random.string('A', 10) INTO codice_tracciamento FROM dual; -- check cod_scon is unique
        SELECT count(*) INTO flag_rigenera FROM consegna  WHERE cod_tracc = codice_tracciamento; 
    END LOOP;
    INSERT INTO CONSEGNA VALUES (codice_tracciamento, 'Poste', data_consegna, cf_acquirente, cod_scontrino, 0); -- Genera la consegna
    commit;
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20031, 'Cliente sconosciuto, compila prima il modulo di registrazione'); 
END CONSEGNA_ACQUISTO;

/*
La procedura consente all'addetto di creare un annuncio di vendita da inserire nella bacheca del negozio.
Riceve in input le caratteristiche dello strumento oggetto dell'annuncio ed il cf del cliente.
Ricordiamo che non sono possibili annunci multipli relativi lo stesso strumento (eccezione "already_on_sale").
Successivamente si controlla che la data di fine annuncio sia futura ed è calcolato il costo dello stesso. 
Se il cliente intende pubblicare l'annuncio per più di una settimana o finchè non sarà venduto il proprio strumento (data fine annuncio NULL)
pagherà una quota standard di 50 euro; in caso contrario pagherà una tariffa oraria di 30 cent.
Infine si registrano le caratteristiche dello strumento usato e si crea l'annuncio di vendita. 
*/

create or replace PROCEDURE CREA_ANNUNCIO (
    CF_CLIENTE IN VARCHAR2, NUMERO_SERIE_STRUMENTO IN VARCHAR2, MARCA_STRUMENTO IN VARCHAR2, MODELLO IN VARCHAR2, PESO IN NUMBER, FINE_ANNUNCIO DATE
    ) AS 
    codice_annuncio NUMBER;
    costo_annuncio NUMBER;
    no_ore NUMBER := 0;
    flag_rigenera NUMBER := 1;
    flag NUMBER := 0;
    already_on_sale EXCEPTION;
    wrong_date EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO flag FROM strumento_usato WHERE num_serie_stru_usato = numero_serie_strumento AND marca_stru_usato = marca_strumento; 
    IF (flag = 1) THEN 
        RAISE already_on_sale;
    END IF;
    WHILE (flag_rigenera <> 0) -- Rigenera finchè il codice scontrino è univoco
    LOOP
        SELECT dbms_random.value(11111, 99999) INTO codice_annuncio FROM dual; -- check cod_annuncio is unique
        SELECT count(*) INTO flag_rigenera FROM annuncio WHERE cod_ann = codice_annuncio; 
    END LOOP;
    IF (fine_annuncio IS NOT NULL) THEN
        IF (fine_annuncio < sysdate) THEN 
            RAISE wrong_date;
        END IF;
        SELECT round(to_number(to_date('14-AGO-20') - sysdate)*24) INTO no_ore FROM dual;
        IF (no_ore > 24*7) THEN 
            costo_annuncio := 50;
        ELSE
            costo_annuncio := no_ore * 0.3; -- Tariffa oraria di 30 cent
        END IF;
    ELSE 
        costo_annuncio := 50;
    END IF;
    INSERT INTO strumento1 VALUES (numero_serie_strumento, marca_strumento, peso, modello); -- Registra le caratteristiche dello strumento 
    INSERT INTO strumento_usato VALUES (numero_serie_strumento, marca_strumento); -- Strumenti in vendita usati
    INSERT INTO annuncio VALUES (codice_annuncio, sysdate, fine_annuncio, costo_annuncio, cf_cliente, numero_serie_strumento, marca_strumento); -- Crea l'annuncio
    COMMIT;

    EXCEPTION
    WHEN already_on_sale THEN
        RAISE_APPLICATION_ERROR(-20026, 'E gia presente un annuncio di vendita relativo a tale strumento');
    WHEN wrong_date THEN 
        RAISE_APPLICATION_ERROR(-20027, 'Data fine annuncio già passata');
END CREA_ANNUNCIO;


/*
La procedura consente al supervisore di creare una promozione, in input è passato il nome, la percentuale
e la categoria di articoli da scontare (strumento/amplificatore/libro).
La function ausiliaria "decode_categoria" restituisce una char(1) che rappresenta la categoria stessa e consente di selezionare
successivamente i codici articoli corretti tra quelli disponibili.
Generiamo un codice univoco per identificare la promozione e inseriamo una tupla nella tabella corrispondente.
Successivamente per ogni categoria di articoli, calcoliamo l'effettiva disponibilità.
Il numero di articoli da scontare, che da specifiche è minore di 5, è calcolato con l'operatore modulo (MOD()), si è scelta questa implementazione
poichè nel caso in cui la disponibilità degli articoli sia scarsa (minore di 5), l'uso di MOD garantisce che il numero di articoli
da scontare non sarà superiore a quelli disponibili (è stato ridefinito NO_DATA_FOUND che sarà lanciato quando la disponibilità del negozio è nulla per quella categoria).
Infine, in un ciclo iterativo, è effettuato l'inserimento degli articoli in articoli_scontati (associazione M:N Articolo - Promozione).

create or replace FUNCTION decode_categoria (TIPO_ART IN VARCHAR2) RETURN CHAR AS 
    cod_art NUMBER;
    categoria_art_promo CHAR(1);
    begin
    SELECT DECODE(LOWER(TIPO_ART), 'amplificatore', 'a' ,'strumento', 's', 'libro', 'l') INTO categoria_art_promo FROM dual;
  RETURN categoria_art_promo;
END decode_categoria;


create or replace PROCEDURE CREA_PROMOZIONE 
(
  NOME IN VARCHAR2,
  PERCENTUALE IN VARCHAR2,
  CATEGORIA_ARTICOLI IN VARCHAR2
) AS 
    codice_promozione promozione.cod_promo%TYPE;
    flag_rigenera NUMBER := 1;
    categoria_art_promo CHAR(1); 
    no_articoli NUMBER := 0;
    art_promo articolo.cod_art%TYPE;
    no_articoli_rimanenti NUMBER := 0;
BEGIN
    categoria_art_promo := decode_categoria(categoria_articoli); -- Individua la categoria da scontare (strumenti/amplificatori/libri)
    WHILE (flag_rigenera <> 0) -- Rigenera finchè il codice promozione è univoco
    LOOP
        SELECT ROUND(DBMS_RANDOM.VALUE(11111, 99999)) INTO codice_promozione FROM dual;
        SELECT count(*) INTO flag_rigenera FROM promozione WHERE cod_promo = codice_promozione; 
    END LOOP;
    INSERT INTO promozione VALUES (codice_promozione, nome, sysdate, sysdate + 10, percentuale);
    
    IF (categoria_art_promo = lower('s')) THEN -- Gli articoli da scontare sono strumenti
        SELECT count(*) INTO no_articoli_rimanenti FROM strumenti_disponibili; -- Calcolo gli strumenti rimanenti
        dbms_output.put_line('Strumenti disponibili: '||no_articoli_rimanenti);
        no_articoli := MOD(no_articoli_rimanenti, 5);
        dbms_output.put_line('Numero strumenti in promo: '||no_articoli);
        FOR lcnt in 1..no_articoli
        LOOP
            SELECT cod_stru INTO art_promo FROM (SELECT cod_stru FROM strumenti_disponibili ORDER BY dbms_random.value) WHERE rownum = 1; -- pick a random articolo from articoli_disponibili
            dbms_output.put_line('Articolo in promo: '||art_promo);
            INSERT INTO articoli_scontati VALUES (art_promo, codice_promozione);
        END LOOP;
        
    ELSIF (categoria_art_promo = lower('a')) THEN
        SELECT count(*) INTO no_articoli_rimanenti FROM amplificatori_disponibili;
        dbms_output.put_line('Amplificatori disponibili: '||no_articoli_rimanenti);
        no_articoli := MOD(no_articoli_rimanenti, 5);
        dbms_output.put_line('Numero strumenti in promo: '||no_articoli);
        FOR lcnt in 1..no_articoli
        LOOP
            SELECT cod_amp INTO art_promo FROM (SELECT cod_amp FROM amplificatori_disponibili ORDER BY dbms_random.value) WHERE rownum = 1;
            dbms_output.put_line('Articolo in promo: '||art_promo);
            INSERT INTO articoli_scontati VALUES (art_promo, codice_promozione);
        END LOOP;
        
    ELSE -- Libri
        SELECT count(*) INTO no_articoli_rimanenti FROM libri_disponibili;
        dbms_output.put_line('Libri disponibili: '||no_articoli_rimanenti);
        no_articoli := MOD(no_articoli_rimanenti, 5);
        dbms_output.put_line('Numero strumenti in promo: '||no_articoli);
        FOR lcnt in 1..no_articoli
        LOOP
            SELECT cod_libro INTO art_promo FROM (SELECT cod_libro FROM libri_disponibili ORDER BY dbms_random.value) WHERE rownum = 1;
            dbms_output.put_line('Articolo in promo: '||art_promo);
            INSERT INTO articoli_scontati VALUES (art_promo, codice_promozione);
        END LOOP;
    END IF;
    COMMIT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20050, 'Articolo non disponibile!');
END CREA_PROMOZIONE;

/*
La procedura consente agli addetti di registrare la richiesta di riparazione per un dato strumento.
In input riceve le specifiche dello stesso ed il cf del richiedente.
Se il richiedente non è registrato, è lanciata un'eccezione. 
I liutai (addetti alla riparazione) hanno un accordo segreto con gli insegnanti dello store: 
registrano un prezzo di riparazione inferiore del 15% in cambio di articoli passati sottobanco! (meglio non fare la spia, i liutai sono figure losche a tratti)
Successivamente è generato un codice per la riparazione ed è incaricato il liutaio con meno riparazioni a carico.
*/
 create or replace PROCEDURE REGISTRA_RIPARAZIONE (
    CF_RICHIEDENTE IN VARCHAR2, NUM_SERIE IN VARCHAR2, MARCA IN VARCHAR2, TIPO_RIPARAZIONE IN VARCHAR2, COSTO IN OUT VARCHAR2, DATA_CONSEGNA IN DATE 
) AS 
    codice_riparazione riparazione.cod_fattura%TYPE;
    codice_liutaio_riparatore liutaio.cod_tess_liu%TYPE;
    flag_registra_persona persona1.cf%TYPE;
    flag_sconto NUMBER := 0;
    flag_rigenera NUMBER := 1;
    
BEGIN
    SELECT cf INTO flag_registra_persona from persona1 WHERE cf = cf_richiedente; -- throws no_data_found
    SELECT COUNT(*) INTO flag_sconto FROM insegnante INS, impiegato IMP WHERE IMP.cod_tess = INS.cod_tess_ins AND imp.cf_imp = cf_richiedente; -- Cerca tra gli insegnanti
    IF (flag_sconto = 1) THEN -- Se il richiedente è un insegnante, sconto il prezzo del 10%
        costo := costo * 0.85;
        dbms_output.put_line('Un insegnante ha richiesto la riparazione, ricalcolo costo: '||costo);
    END IF;

    SELECT ROUND(DBMS_RANDOM.VALUE(10000, 19999)) INTO codice_riparazione FROM dual;
    SELECT cod_tess_liu_rip INTO codice_liutaio_riparatore    -- Seleziona un/il liutaio che ha effettuato meno riparazioni
    FROM (SELECT cod_tess_liu_rip, COUNT(*) as frequency FROM riparazione GROUP BY cod_tess_liu_rip ORDER BY frequency ASC) WHERE rownum = 1;
    dbms_output.put_line('Liutaio incaricato: '||codice_liutaio_riparatore);
    INSERT INTO RIPARAZIONE VALUES (codice_riparazione, tipo_riparazione, sysdate, data_consegna, cf_richiedente, codice_liutaio_riparatore, num_serie, marca, costo);
    COMMIT;
    
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20030, 'Richiedente sconosciuto, effettuare prima la registrazione');
END REGISTRA_RIPARAZIONE;


/*
La procedura permette agli utenti che hanno effettuato un ordine consegnato a domicilio di avviare la procedura di reso (se sono rispettati i termini per il reso) *.
Riceve in input il cf dell'acquirente, il codice dello scontrino relativo all'ordine oggetto di reso, la motivazione e la data di reso.
Controlliamo che l'utente abbia effettuato tale ordine e che l'ordine stesso sia stato consegnato (data_reso > data_consegna) e successivamente generiamo un codice per
identificare in modo univoco il reso.
Se l'acquisto iniziale includeva più articoli, simuliamo il numero di articoli da rendere attraverso la generazione di un intero pseudo-casuale compreso tra [1, N],
dove N rappresenta il numero di articoli acquistati.
Infine con l'ausilio di un cursore, inseriamo il codice_reso e il/gli articolo/i da rendere nella tabella e_coinvolto (assiciazione M:N RESO)
*/
create or replace PROCEDURE RENDI_ARTICOLI
(
  CF_ACQUIRENTE IN VARCHAR2,
  COD_SCONTRINO IN VARCHAR2,
  MOTIVAZIONE IN VARCHAR2,
  DATA_RESO IN DATE 
) AS
    CURSOR C1 IS SELECT cod_art_det FROM dettaglio_acquisto WHERE cod_scon_det = cod_scontrino;
    data_consegna DATE;
    flag_rigenera NUMBER := 1;
    acquisto_multiplo NUMBER := 0;
    no_articoli_da_rendere NUMBER := 1;
    flag_acquirente acquirente.cf_acq%TYPE;
    flag_acquisto acquisto.cod_scon%TYPE;
    codice_reso reso.cod_reso%TYPE;
    articolo_da_rendere articolo.cod_art%TYPE := 1;
    wrong_customer EXCEPTION;
    wrong_date EXCEPTION;
    flag NUMBER := 1;
BEGIN
    SELECT cf_acq_cons, cod_scon_cons INTO flag_acquirente, flag_acquisto FROM consegna
    WHERE cf_acq_cons = cf_acquirente and cod_scon_cons = cod_scontrino; -- Può generare no_data_found
    SELECT data_arrivo INTO data_consegna FROM consegna WHERE cod_scon_cons = cod_scontrino; 
    IF (data_consegna > data_reso) THEN -- Verifico che il cliente abbia prima ricevuto l'ordine
        RAISE wrong_date;
    END IF;
    WHILE (flag_rigenera <> 0) -- Rigenera finchè il codice reso è univoco
    LOOP
        SELECT ROUND(DBMS_RANDOM.VALUE(11111, 99999)) INTO codice_reso FROM dual;
        SELECT count(*) INTO flag_rigenera FROM reso WHERE cod_reso = codice_reso; 
    END LOOP;
    INSERT INTO RESO VALUES (codice_reso, motivazione, data_reso, cod_scontrino);
    SELECT COUNT(*) INTO acquisto_multiplo FROM dettaglio_acquisto WHERE cod_scon_det = cod_scontrino GROUP BY cod_scon_det; -- L'acquirente potrebbe aver acquistato più articoli
    SELECT ROUND(DBMS_RANDOM.VALUE(1, acquisto_multiplo)) INTO no_articoli_da_rendere FROM dual; -- Genero un numero pseudo-casuale di articoli da rendere 
    dbms_output.put_line('NO. articoli coinvolti nel reso: '||no_articoli_da_rendere);
    OPEN C1; -- The cursor may be deprecated, but the insertion on "e_coinvolto" is simpler to build and more readable
    FOR lcntr IN 1..no_articoli_da_rendere 
    LOOP
        FETCH C1 INTO articolo_da_rendere;
        INSERT INTO e_coinvolto VALUES (codice_reso, articolo_da_rendere);
        dbms_output.put_line('Cod articolo oggetto del reso: '||articolo_da_rendere);
    END LOOP;
    CLOSE C1;    
    COMMIT;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20011, 'Il cliente non ha effettuato tale ordine!');
WHEN wrong_date THEN
    RAISE_APPLICATION_ERROR(-20012, q'[Impossibile avviare il reso, l'ordine è ancora in transito!]');
END RENDI_ARTICOLI;

create or replace PROCEDURE NOMINA_ADDETTO_DEL_MESE 
AS 
    mese_target VARCHAR2(15) := to_char(add_months(sysdate, -1), 'mon'); -- Mese precedente
    anno_target NUMBER := extract(year from to_date(add_months(sysdate, -1))); -- Anno relativo al mese precedente (fa la differenza se il mese corrente è Gennaio)
    addetto NUMBER(5);
    no_vendite NUMBER(3);
    fatturato NUMBER(7,2);
BEGIN
    /* 
    La query seleziona l'addetto che ha effettuato più vendite, il numero di vendite ed il fatturato nel corso del mese_target
    (ovvero il mese precedente a quello corrente)
    */
    select * INTO addetto, fatturato, no_vendite from 
        (select cod_tess_add_vendita, sum(prezzo), count(*) from acquisto ACQ, articolo A JOIN dettaglio_acquisto DA ON A.cod_art=DA.cod_art_det
        where ACQ.cod_scon = DA.cod_scon_det and to_char(data_a, 'mon') = lower(mese_target) and extract(year from data_a) = anno_target
        GROUP BY cod_tess_add_vendita ORDER BY count(*) DESC)
    WHERE rownum=1;
    -- Inseriamo in addetto_del_mese
    INSERT INTO addetto_del_mese(cod_tess_add_mese, no_vendite, fatturato, mese, anno) VALUES (addetto, no_vendite, fatturato, mese_target, anno_target);
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN -- Se non avvengono vendite il un interno mese, lo Store è presumibilmente in ferie
    RAISE_APPLICATION_ERROR(-20050, 'Nessuna vendita in tale periodo, lo Store è chiuso causa ferie!');
END NOMINA_ADDETTO_DEL_MESE;
