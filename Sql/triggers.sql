/*
 1) Lo stipendio mensile di un Addetto reparto dev’essere maggiore di 900 e minore di 1400 euro,
    mentre lo stipendio del supervisore è compreso varia tra 1600 e 2000 euro.
*/
create or replace TRIGGER "BIU_STIPENDIO_ADDETTO" BEFORE INSERT OR UPDATE ON ADDETTO_REPARTO
FOR EACH ROW
DECLARE
    stipendio_attuale NUMBER;
    wrong_salary_superv EXCEPTION;
    wrong_salary_add EXCEPTION;
BEGIN
    SELECT stipendio INTO stipendio_attuale FROM impiegato WHERE cod_tess = :NEW.cod_tess_add;
    IF (:NEW.cod_tess_sup IS NOT NULL) THEN -- Addetto semplice
        IF (stipendio_attuale NOT BETWEEN 900 AND 1600) THEN
            RAISE wrong_salary_add;
        END IF;
    ELSE -- Supervisore
        IF (stipendio_attuale NOT BETWEEN 1600 AND 2000) THEN
            RAISE wrong_salary_superv;
        END IF;
    END IF;
EXCEPTION
    WHEN wrong_salary_add THEN
        RAISE_APPLICATION_ERROR(-20000, 'Salary out of range for a simple employee');
    WHEN wrong_salary_superv THEN
        RAISE_APPLICATION_ERROR(-20000, 'Salary out of range for a manager');
END;

/*
2) La politica di assunzione dello Store favorisce impiegati giovani.
   L’HR rifiuta le candidature di persone over 55 dicendo loro che li ricontatterà (senza mai farlo!)
*/
create or replace TRIGGER BI_AGE_CHECK
BEFORE INSERT ON IMPIEGATO
FOR EACH ROW
DECLARE
    age_employee NUMBER;
    too_young EXCEPTION;
    too_old EXCEPTION;
BEGIN
    SELECT round(months_between(sysdate, dn)/12) INTO age_employee FROM persona1 WHERE cf = :NEW.cf_imp;
    IF (age_employee < 18) THEN
        RAISE too_young;
    ELSIF (age_employee > 55) THEN
        RAISE too_old;
    END IF;
EXCEPTION
WHEN too_young THEN
    RAISE_APPLICATION_ERROR(-20005, 'HR: Too young buddy, retry next year!');
WHEN too_old THEN
     RAISE_APPLICATION_ERROR(-20006, q'[HR: Thanks sir, we'll let you know! (never calls)]');
END;

/*
3) Un insegnante ordinario è coinvolto al più in 3 corsi diversi.
  Ogni corso extra comporta un bonus mensile pari al 5% dello stipendio attuale fino ad un massimo di 6 corsi.
*/
create or replace TRIGGER "BI_CORSI_EXTRA" BEFORE INSERT OR UPDATE OF COD_TESS_INS_CORSO ON CORSO
FOR EACH ROW
DECLARE
    conta NUMBER;
    stipendio_attuale NUMBER;
    max_corsi_extra EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO conta FROM CORSO WHERE cod_tess_ins_corso = :NEW.COD_TESS_INS_CORSO GROUP BY cod_tess_ins_corso;
    IF (conta BETWEEN 3 AND 5) THEN
        SELECT stipendio INTO stipendio_attuale FROM impiegato WHERE cod_tess = :NEW.cod_tess_ins_corso;
        UPDATE impiegato SET stipendio = stipendio_attuale * 1.05 WHERE cod_tess = :NEW.cod_tess_ins_corso;
    ELSIF (conta >= 6) THEN
        RAISE max_corsi_extra;
    END IF;
EXCEPTION
WHEN max_corsi_extra THEN
    RAISE_APPLICATION_ERROR(-20001, 'Teacher already reached maximum extra courses!');
END;

-- 4) Se un corso extra è annullato o cambia l’insegnante di riferimento, il bonus precedentemente concesso all’insegnante è ripristinato.
create or replace PROCEDURE DECURTA_STIPENDIO (COD_TESS_INS IN NUMBER) AS
    stipendio_attuale NUMBER;
BEGIN
  SELECT stipendio INTO stipendio_attuale FROM impiegato WHERE COD_TESS_INS = cod_tess;
    UPDATE impiegato SET stipendio = stipendio_attuale * 0.95  WHERE cod_tess = COD_TESS_INS;
END DECURTA_STIPENDIO;

create or replace TRIGGER "AD_CORSI_EXTRA" AFTER DELETE ON CORSO
FOR EACH ROW
DECLARE
    conta NUMBER;
    stipendio_attuale NUMBER;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    SELECT COUNT(*) INTO conta FROM CORSO WHERE :OLD.COD_TESS_INS_CORSO IN cod_tess_ins_corso GROUP BY cod_tess_ins_corso;
    IF (conta BETWEEN 3 AND 5) THEN
        DECURTA_STIPENDIO(:OLD.COD_TESS_INS_CORSO);
        COMMIT;
    END IF;
END;


-- 5) Il Music-Store prevede un bonus del 10%  per tutti i nuovi insegnanti al di sotto dei 30 anni che vantano un diploma conseguito all’Accademia o al Conservatorio.
create or replace TRIGGER AI_BONUS_U30
AFTER INSERT ON INSEGNANTE
FOR EACH ROW
DECLARE
    stipendio_attuale NUMBER;
    cf_employee CHAR(16);
    age_employee NUMBER;
    titolo CHAR;
BEGIN
    SELECT cf_imp, stipendio INTO cf_employee, stipendio_attuale FROM impiegato WHERE :NEW.cod_tess_ins = cod_tess;
    SELECT round(months_between(sysdate, dn)/12) INTO age_employee FROM persona1 WHERE cf_employee = cf;
    IF (age_employee <= 30 AND upper(:NEW.titolo_studio) IN ('ACCADEMIA', 'CONSERVATORIO')) THEN
        UPDATE impiegato SET stipendio = stipendio_attuale * 1.1 WHERE cod_tess = :NEW.cod_tess_ins;
    END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021, 'Codice tesserino impiegato errato!');
END;

/*
6) 6.	Ogni cliente ha 2 settimane per richiedere un reso relativo ad un ordine,
  al termine delle quali scade il diritto di reso. Non è permessa la restituzione di più articoli compresi nello stesso acquisto in giorni differenti.
*/
create or replace TRIGGER BI_TERMINE_RESO
BEFORE INSERT ON RESO
FOR EACH ROW
DECLARE
    data_acquisto DATE;
    flag_reso NUMBER := 0;
    reso_not_allowed EXCEPTION;
    reso_already EXCEPTION;
BEGIN
    SELECT data_a INTO data_acquisto FROM acquisto WHERE cod_scon = :NEW.cod_scon_reso; -- Recupero la data di acquisto
    SELECT count(*) INTO flag_reso FROM reso WHERE cod_scon_reso = :NEW.cod_scon_reso; -- Verifico che non ci sono già resi per tale acquisto
    IF (flag_reso > 0) THEN
        RAISE reso_already;
    ELSIF (:NEW.data_reso - data_acquisto > 14 OR data_acquisto > :NEW.data_reso) THEN -- E' scaduto il termine per effettuare il reso
        RAISE reso_not_allowed;
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20005, 'Codice scontrino errato!');
WHEN reso_not_allowed THEN
    RAISE_APPLICATION_ERROR(-20006, 'Reso non consentito, terminato il periodo per il reso o data non valida!');
WHEN reso_already THEN
    RAISE_APPLICATION_ERROR(-20007, q'[Reso relativo all'acquisto già presente!]');
END;

/*
7) Trigger composito che aggiorna i costi di spedizione sulla base del prezzo relativo all'articolo.
  Trigger compositi hanno la caratteristica di firing-points multipli con la quale si può evitare l'errore "mutating-table".
  Si è preferito utilizzare una PL/SQL table (una futura implementazione potrebbe prevedere una hash map di NUMBER indicizzata dal codice di tracciamento),
  dove ogni record contiene il numero di tracciamento e i costi di spedizione.
  Nel row-level i codici di tracciamento e i costi di consegna (calcolati con la procedura TOTALE_ACQUISTO()) sono memorizzati nell'apposita entry della table
  (l'indice incrementa di 1 after each row).
  L'effettivo aggiornamento del campo costi_spedizione della table consegna avviene nello statement-level, ciclando per ogni record presente nella table.
*/
create or replace TRIGGER CALCOLO_COSTI_SPEDIZIONE
FOR INSERT ON CONSEGNA
COMPOUND TRIGGER
    TYPE r_consegna_type IS RECORD (
        id_consegna consegna.cod_tracc%TYPE,
        costi_consegna consegna.costi_spedizione%TYPE);
    TYPE array_r_consegna_type IS TABLE OF r_consegna_type INDEX BY PLS_INTEGER;
    a_consegna array_r_consegna_type;
    totale NUMBER;

AFTER EACH ROW IS
BEGIN
    a_consegna(a_consegna.COUNT+1).id_consegna := :NEW.cod_tracc;
    TOTALE_ACQUISTO (:NEW.cod_scon_cons, totale);
    IF (totale < 250) THEN
        a_consegna(a_consegna.COUNT).costi_consegna := 33;
    ELSIF (totale BETWEEN 251 AND 400) THEN
        a_consegna(a_consegna.COUNT).costi_consegna := 12;
    ELSE
        a_consegna(a_consegna.COUNT).costi_consegna := 0;
    END IF;
END AFTER EACH ROW;

AFTER STATEMENT IS
BEGIN
    FOR lcntr IN a_consegna.FIRST..a_consegna.LAST
    LOOP
        UPDATE consegna
        SET costi_spedizione = a_consegna(lcntr).costi_consegna
        WHERE cod_tracc = a_consegna(lcntr).id_consegna;
    END LOOP;
END AFTER STATEMENT;
END;




/*
8) La consegna relativa ad un acquisto è effettuata entro 7 giorni dal pagamento.
   Se per motivi logistici la data di consegna prevista non soddisfa i tempi di consegna,
   la consegna sarà inserita nelle consegne in ritardo e gli articoli posti in giacenza.
   Verrà programmato un nuovo tentativo di consegna il prossimo Lunedì.
   Il termine della giacenza è fissato ad 1 giorno prima della riconsegna
   (i magazzinieri caricano i furgoni di domenica per consentire ai corrieri di arrivare in tempo all’indirizzo di consegna il giorno successivo).
  */
create or replace TRIGGER "BIU_RICONSEGNA" AFTER INSERT OR UPDATE OF DATA_ARRIVO ON CONSEGNA
FOR EACH ROW
DECLARE
    data_acquisto DATE;
    riconsegna EXCEPTION;
BEGIN
    SELECT a.data_a into data_acquisto
    FROM acquisto a
    WHERE :NEW.cod_scon_cons = a.cod_scon;
    IF (:NEW.data_arrivo - data_acquisto) > 7 THEN
        insert into consegna_in_ritardo VALUES (:NEW.cod_tracc, :NEW.data_arrivo, NEXT_DAY(:NEW.data_arrivo,'DOM'), NEXT_DAY(:NEW.data_arrivo + 1,'LUN'));
        raise riconsegna;
    end if;
exception
when riconsegna then
    DBMS_OUTPUT.PUT_LINE('Consegna in ritardo! Inizio giacenza.');
END;

/*
9) Trigger composito che controlla prima dell'inserimento di una nuova tupla in articoli_scontati che gli articoli oggetto di tale promozione non siano più di 5,
   in tal caso lancia un'eccezione.
   Viceversa dopo l'inserimento della tupla procede con l'aggiornamento del prezzo originale dell'articolo.
   In caso di inserimento l'articolo verrà scontato del valore pari alla percentuale della promozione, in caso di cancellazione è ripristinato il prezzo originale.
*/
create or replace TRIGGER "AID_APPLICA_SCONTO"
FOR DELETE OR INSERT ON ARTICOLI_SCONTATI
COMPOUND TRIGGER
    costo_attuale NUMBER;
    sconto_da_applicare NUMBER;
    too_much_items EXCEPTION;
    conta_items NUMBER;
    BEFORE EACH ROW IS
    BEGIN
        SELECT COUNT(*) INTO conta_items FROM articoli_scontati WHERE cod_promo_sco = :NEW.cod_promo_sco;
        IF (conta_items > 4) THEN
            RAISE too_much_items;
        END IF;
    EXCEPTION
    WHEN too_much_items THEN
        RAISE_APPLICATION_ERROR(-20018, 'Raggiunto numero massimo di articoli per tale promozione!');
    END BEFORE EACH ROW;

    AFTER EACH ROW IS
    BEGIN
        SELECT prezzo INTO costo_attuale FROM articolo WHERE cod_art = :NEW.cod_art_sco;
        SELECT percentuale INTO sconto_da_applicare FROM promozione WHERE cod_promo = :NEW.cod_promo_sco;
        IF INSERTING THEN
            UPDATE articolo SET prezzo = prezzo - (prezzo * sconto_da_applicare/100) WHERE cod_art = :NEW.cod_art_sco;
        ELSE
            UPDATE articolo SET prezzo = prezzo / (1 - (sconto_da_applicare/100)) WHERE cod_art = :OLD.cod_art_sco;
        END IF;
    END AFTER EACH ROW;
    END;

-- 10) Un cliente può noleggiare al più 3 strumenti contemporaneamente
CREATE OR REPLACE TRIGGER BI_LIMITE_NOLEGGIO 
BEFORE INSERT ON NOLEGGIA
FOR EACH ROW
DECLARE
    conta NUMBER := 0;
    troppi_strumenti_noleggiati EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO conta FROM noleggia WHERE cf_acq_nol = :NEW.cf_acq_nol AND fine_noleggio > :NEW.inizio_noleggio;
    IF (conta >= 3) THEN
        RAISE troppi_strumenti_noleggiati;
    END IF;
    EXCEPTION
    WHEN troppi_strumenti_noleggiati THEN
        RAISE_APPLICATION_ERROR(-20032, 'Non puoi noleggiare un nuovo strumento, restituisci prima gli altri!');
END;