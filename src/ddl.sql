DROP TABLE persona1;
DROP TABLE persona2;
DROP TABLE evento;
DROP TABLE acquirente;
DROP TABLE allievo;
DROP TABLE impiegato;
DROP TABLE addetto_reparto;
DROP TABLE insegnante;
DROP TABLE liutaio;
DROP TABLE biglietto1;
DROP TABLE biglietto2;
DROP TABLE reparto;
DROP TABLE affitto_sala_prove;
DROP TABLE acquisto;
DROP TABLE promozione;
DROP TABLE articolo;
DROP TABLE dettaglio_acquisto;
DROP TABLE articoli_scontati;
DROP TABLE strumento1;
DROP TABLE strumento2;
DROP TABLE strumento3;
DROP TABLE strumento_negozio;
DROP TABLE strumento_usato;
DROP TABLE amplificatore;
DROP TABLE libro;
DROP TABLE annuncio;
DROP TABLE consegna;
DROP TABLE reso;
DROP TABLE e_coinvolto;
DROP TABLE corso;
DROP TABLE lezione;
DROP TABLE e_iscritto;
DROP TABLE frequenta;
DROP TABLE noleggio;
DROP TABLE riguarda;
DROP TABLE riparazione;
DROP TABLE consegna_in_ritardo;
DROP TABLE addetto_del_mese;


CREATE TABLE persona1 (
    cf              CHAR(16)            PRIMARY KEY,
    nome            VARCHAR2(20)        NOT NULL,
    cognome         VARCHAR2(20)        NOT NULL,
    sesso           CHAR(1)             CHECK (sesso='M'OR sesso='F' OR sesso='N') NOT NULL,
    dn              DATE                NOT NULL,
    telefono        CHAR(13)            NOT NULL,
    via             VARCHAR2(30)        NOT NULL,
    numero          NUMBER(3)           CHECK (numero BETWEEN 1 AND 999) NOT NULL,
    citta           VARCHAR2(20)        NOT NULL
);
CREATE TABLE persona2(
    citta           VARCHAR2(25)        PRIMARY KEY,
    prefisso        VARCHAR2(5)         NOT NULL
);

CREATE TABLE evento(
    cod_evento              NUMBER(5)           PRIMARY KEY,
    organizzatore           VARCHAR2(30),
    data_evento             DATE                NOT NULL,
    luogo_evento            VARCHAR2(20)        NOT NULL,
    genere_evento           VARCHAR2(20)        DEFAULT('Concerto') NOT NULL,
    durata_evento           NUMBER(2)           DEFAULT 5 NOT NULL
);

CREATE TABLE acquirente(
    cf_acq                  CHAR(16)            PRIMARY KEY,
    CONSTRAINT fka1 FOREIGN KEY (cf_acq) REFERENCES persona1(cf) ON DELETE CASCADE
);

CREATE TABLE allievo(
    cf_allievo          CHAR(16)        PRIMARY KEY,
    CONSTRAINT fkall FOREIGN KEY (cf_allievo) REFERENCES persona1(cf) ON DELETE CASCADE
);

CREATE TABLE impiegato(
    cf_imp                      CHAR(16)            PRIMARY KEY,
    cod_tess                    NUMBER(5)           UNIQUE NOT NULL,
    data_assunzione             DATE                NOT NULL,
    data_licenz                 DATE,
    stipendio                   NUMBER(6,2)         NOT NULL,
    CONSTRAINT Impiegato_ok CHECK (data_licenz > data_assunzione OR data_licenz IS NULL),
    CONSTRAINT fki1 FOREIGN KEY (cf_imp) REFERENCES persona1(cf) ON DELETE CASCADE
);

CREATE TABLE addetto_reparto(        
    cod_tess_add               NUMBER(5)             PRIMARY KEY,
    cod_tess_sup               NUMBER(5),
    CONSTRAINT fkar1 FOREIGN KEY (cod_tess_add) REFERENCES impiegato(cod_tess) ON DELETE CASCADE,
    CONSTRAINT fkar3 FOREIGN KEY (cod_tess_sup) REFERENCES addetto_reparto(cod_tess_add) ON DELETE CASCADE
);


CREATE TABLE insegnante(
    cod_tess_ins        NUMBER(5)       PRIMARY KEY,
    nazionalita         VARCHAR(20)     DEFAULT('Ita')      NOT NULL,
    titolo_studio       VARCHAR(20),
    CONSTRAINT fkins FOREIGN KEY (cod_tess_ins) REFERENCES impiegato(cod_tess) ON DELETE CASCADE
);

CREATE TABLE liutaio(
    cod_tess_liu        NUMBER(5)       PRIMARY KEY,
    qualifica           VARCHAR2(20),
    CONSTRAINT fkl FOREIGN KEY (cod_tess_liu) REFERENCES impiegato(cod_tess) ON DELETE CASCADE
);

CREATE TABLE biglietto1(
    cod_biglietto               NUMBER(5)           PRIMARY KEY,
    tipo_biglietto              VARCHAR(20)         DEFAULT('Standard') NOT NULL,
    cod_evento_b                NUMBER(5)           NOT NULL,
    cod_tess_add_b              NUMBER(5),
    CONSTRAINT fkb1 FOREIGN KEY (cod_evento_b) REFERENCES evento(cod_evento) ON DELETE CASCADE,
    CONSTRAINT fkb2 FOREIGN KEY (cod_tess_add_b) REFERENCES addetto_reparto(cod_tess_add) ON DELETE CASCADE,
    CONSTRAINT tipo_ok CHECK (INITCAP(tipo_biglietto) IN ('Standard', 'Premium'))
);

CREATE TABLE biglietto2(
    tipo_biglietto              VARCHAR(20)         PRIMARY KEY,
    costo_biglietto             NUMBER(4,2)         NOT NULL
);


CREATE TABLE reparto(
    cod_reparto             NUMBER(5)             PRIMARY KEY,
    nome_reparto            VARCHAR2(20)          NOT NULL,
    cod_tess_supr           NUMBER(5)             NOT NULL,
    CONSTRAINT fkr FOREIGN KEY (cod_tess_supr) REFERENCES addetto_reparto(cod_tess_add) ON DELETE CASCADE
);


CREATE TABLE affitto_sala_prove(
    cod_pren                NUMBER(5)           PRIMARY KEY,
    num_sala                NUMBER(2)           NOT NULL,
    tariffa                 NUMBER(4,2)         NOT NULL,
    data_pren               DATE                NOT NULL,
    cf_acq_sp               CHAR(16)            NOT NULL,
    durata                  NUMBER(2,1)         NOT NULL,
    CONSTRAINT fksp FOREIGN KEY (cf_acq_sp) REFERENCES acquirente(cf_acq) ON DELETE CASCADE
    --ORARI
);

CREATE TABLE acquisto (
    cod_scon                    CHAR(10)        PRIMARY KEY,
    mod_pagamento               VARCHAR2(30)    CHECK (INITCAP (mod_pagamento) IN ('Contanti', 'Carta', 'Rate')) NOT NULL,
    data_a                      DATE            NOT NULL
);

CREATE TABLE promozione(
    cod_promo           NUMBER(5)        PRIMARY KEY,
    nome_promo          VARCHAR2(20)     DEFAULT('Generica'),
    inizio_promo        DATE             NOT NULL,
    fine_promo          DATE,
    percentuale         NUMBER(2,0)      CHECK (percentuale BETWEEN 10 AND 40) NOT NULL,
    CONSTRAINT Promo_ok CHECK (fine_promo > inizio_promo OR fine_promo IS NULL)
);

CREATE TABLE articolo (
    cod_art                     NUMBER(5)       PRIMARY KEY,
    prezzo                      NUMBER(5,2)     NOT NULL,
    union_helper                CHAR(1)         CHECK(INITCAP(union_helper IN ('S', 'A', 'L') NOT NULL;
);

CREATE TABLE dettaglio_acquisto(
    cod_scon_det                CHAR(10),
    cod_art_det                 NUMBER(5),
    CONSTRAINT dett_acq_pk PRIMARY KEY (cod_scon_det, cod_art_det),
    CONSTRAINT fkda1 FOREIGN KEY (cod_scon_det) REFERENCES acquisto(cod_scon) ON DELETE CASCADE,
    CONSTRAINT fkda2 FOREIGN KEY (cod_art_det) REFERENCES articolo(cod_art) ON DELETE CASCADE
);


CREATE TABLE articoli_scontati(
    cod_art_sco                 NUMBER(5),
    cod_promo_sco               NUMBER(5),
    CONSTRAINT art_sco_pk PRIMARY KEY (cod_art_sco, cod_promo_sco),
    CONSTRAINT fkas1 FOREIGN KEY (cod_art_sco) REFERENCES articolo(cod_art) ON DELETE CASCADE,
    CONSTRAINT fkas2 FOREIGN KEY (cod_promo_sco) REFERENCES promozione(cod_promo) ON DELETE CASCADE
);

CREATE TABLE strumento1(
    num_serie           CHAR(10),
    marca               VARCHAR(20),
    peso                NUMBER(5,2),
    prezzo              NUMBER(5,2),
    modello             VARCHAR(20)     NOT NULL,
    CONSTRAINT strumento_pk PRIMARY KEY (num_serie, marca),
    CONSTRAINT marca_ok CHECK(INITCAP(marca) IN ('HarleyBenton', 'Yamaha', 'Gibson', 'Fender'))
);

CREATE TABLE strumento2(
    nome                VARCHAR(20)     PRIMARY KEY,
    categoria           VARCHAR(20)     NOT NULL,
    CONSTRAINT categorie_ok CHECK(INITCAP(categoria) IN ('Aerofono', 'Membranofono', 'Idiofono', 'Cordofono', 'Archi'))
);

CREATE TABLE strumento3(
    modello             VARCHAR(20)     PRIMARY KEY,
    nome                VARCHAR(20)     NOT NULL
);

CREATE TABLE strumento_negozio(
    num_serie_stru_neg       CHAR(10),
    marca_stru_neg           VARCHAR2(20),
    cod_stru                 NUMBER(5)      NOT NULL,
    CONSTRAINT pk_stru_neg PRIMARY KEY (num_serie_stru_neg, marca_stru_neg),
    CONSTRAINT fk_stru_neg_comp FOREIGN KEY (num_serie_stru_neg, marca_stru_neg)  REFERENCES strumento1(num_serie, marca) ON DELETE CASCADE,
    CONSTRAINT fk_str_neg_art FOREIGN KEY (cod_stru) REFERENCES articolo(cod_art) ON DELETE CASCADE
);

CREATE TABLE strumento_usato(
    num_serie_stru_usato     CHAR(10)       NOT NULL,
    marca_stru_usato         VARCHAR2(20)   NOT NULL,
    CONSTRAINT strumento_usato_pk PRIMARY KEY (num_serie_stru_usato, marca_stru_usato),
    CONSTRAINT fk_stru_usato_comp FOREIGN KEY (num_serie_stru_usato, marca_stru_usato)  REFERENCES strumento1(num_serie, marca)
);

CREATE TABLE amplificatore(
    num_serie_amp       CHAR(10),
    marca               VARCHAR(20),
    prezzo_amp          NUMBER(6,2)     NOT NULL,
    potenza             NUMBER(4)       DEFAULT 200,
    tipo_amp            VARCHAR(12)     DEFAULT('Generico'),
    num_uscite          NUMBER(2)       DEFAULT 4,
    cod_amp             NUMBER(5)       NOT NULL,
    CONSTRAINT pk_amp PRIMARY KEY (num_serie_amp, marca),
    CONSTRAINT fk_amp FOREIGN KEY (cod_amp) REFERENCES articolo(cod_art) ON DELETE CASCADE
);

CREATE TABLE libro(
    isbn                CHAR(17)        PRIMARY KEY,
    titolo              VARCHAR(20)     NOT NULL,
    edizione            NUMBER(2)       CHECK(edizione > 0) NOT NULL,
    num_pagine          NUMBER(4),
    autore_1            VARCHAR(20)     NOT NULL,
    autore_2            VARCHAR(20),
    autore_3            VARCHAR(20),
    prezzo_lib          NUMBER(5,2)     NOT NULL,
    cod_libro           NUMBER(5)       NOT NULL,
    CONSTRAINT libro_fk FOREIGN KEY (cod_libro) REFERENCES articolo(cod_art) ON DELETE CASCADE
);

CREATE TABLE annuncio(
    cod_ann         NUMBER(5)           PRIMARY KEY,
    inizio_ann      DATE                NOT NULL,
    fine_ann        DATE,
    costo_ann       NUMBER(4,2)         NOT NULL,
    cf_acq_ann          CHAR(16)        NOT NULL, 
    num_serie_stru_ann   CHAR(10)       NOT NULL,
    marca_stru_ann      VARCHAR2(20)    NOT NULL,
    CONSTRAINT Annuncio_ok CHECK (fine_ann > inizio_ann OR fine_ann IS NULL),
    CONSTRAINT fk1_ann FOREIGN KEY (cf_acq_ann) REFERENCES acquirente(cf_acq) ON DELETE CASCADE,
    CONSTRAINT fk_ann_comp FOREIGN KEY (num_serie_stru_ann, marca_stru_ann)  REFERENCES strumento_usato(num_serie_stru_usato, marca_stru_usato)
);

CREATE TABLE consegna (
    cod_tracc               CHAR(10)        PRIMARY KEY,
    corriere                VARCHAR2(30)    NOT NULL,
    data_arrivo             DATE            NOT NULL,
    cf_acq_cons             CHAR(16)        NOT NULL,
    cod_scon_cons           CHAR(10)        UNIQUE NOT NULL,
    CONSTRAINT fk_acq FOREIGN KEY (cf_acq_cons) REFERENCES acquirente(cf_acq) ON DELETE CASCADE,
    CONSTRAINT fk_cod_scon FOREIGN KEY (cod_scon_cons) REFERENCES acquisto(cod_scon) ON DELETE CASCADE
);

CREATE TABLE reso(
    cod_reso                    NUMBER(5)       PRIMARY KEY,
    motivazione                 VARCHAR2(30),
    data_reso                   DATE            NOT NULL
);
drop table e_coinvolto;
CREATE TABLE e_coinvolto(
    cod_reso_ec                 NUMBER(5),
    cod_art_ec                  NUMBER(5),
    CONSTRAINT ec_pk PRIMARY KEY (cod_reso_ec, cod_art_ec),
    CONSTRAINT fk_ec_reso FOREIGN KEY (cod_reso_ec) REFERENCES reso(cod_reso) ON DELETE CASCADE,
    CONSTRAINT fk_ec_art FOREIGN KEY (cod_art_ec) REFERENCES articolo(cod_art) ON DELETE CASCADE
);

CREATE TABLE corso(
    cod_corso           NUMBER(5),
    cod_tess_ins_corso  NUMBER(5),
    nome_corso          VARCHAR2(20)    NOT NULL,
    inizio_corso        DATE            NOT NULL,
    fine_corso          DATE            NOT NULL,
    prezzo_corso        NUMBER(6,2)     NOT NULL,
    CONSTRAINT corso_pk PRIMARY KEY (cod_tess_ins_corso, cod_corso),
    CONSTRAINT Corso_ok CHECK (fine_corso > inizio_corso),
    CONSTRAINT fkc1 FOREIGN KEY (cod_tess_ins_corso) REFERENCES insegnante(cod_tess_ins) ON DELETE CASCADE
);

CREATE TABLE lezione(
    cod_lez             NUMBER(5),
    cod_corso_l         NUMBER(5),
    cod_tess_ins_lez    NUMBER(5),
    tipo_lez            VARCHAR(12)     DEFAULT('Gruppo'),
    data_lez            DATE            NOT NULL,
    durata_lez          NUMBER(2,1)     DEFAULT 2,
    CONSTRAINT lez_pk PRIMARY KEY (cod_tess_ins_lez, cod_corso_l, cod_lez),
    CONSTRAINT fk_lez FOREIGN KEY (cod_corso_l, cod_tess_ins_lez) REFERENCES corso(cod_corso, cod_tess_ins_corso)  
);

CREATE TABLE e_iscritto(
    cf_allievo_i        CHAR(16),
    cod_corso_i         NUMBER(5),
    cod_tess_ins_corso_i NUMBER(5),
    CONSTRAINT eiscritto_pk PRIMARY KEY (cf_allievo_i, cod_corso_i, cod_tess_ins_corso_i),
    CONSTRAINT fkei1 FOREIGN KEY (cf_allievo_i) REFERENCES allievo(cf_allievo) ON DELETE CASCADE,
    CONSTRAINT fkei2 FOREIGN KEY (cod_corso_i, cod_tess_ins_corso_i) REFERENCES corso(cod_corso, cod_tess_ins_corso) ON DELETE CASCADE
);

CREATE TABLE frequenta(
    cod_tess_ins_lez_f      NUMBER(5),
    cod_corso_lez_f         NUMBER(5),
    cod_lez_f               NUMBER(5),
    cf_allievo_f            CHAR(16),
    CONSTRAINT fr_pk_comp PRIMARY KEY (cod_tess_ins_lez_f, cod_corso_lez_f, cod_lez_f, cf_allievo_f),
    CONSTRAINT fkf1 FOREIGN KEY (cod_tess_ins_lez_f, cod_corso_lez_f, cod_lez_f) REFERENCES lezione(cod_tess_ins_lez, cod_corso_l, cod_lez) ON DELETE CASCADE,
    CONSTRAINT fk3 FOREIGN KEY (cf_allievo_f) REFERENCES allievo(cf_allievo) ON DELETE CASCADE
);

CREATE TABLE noleggia(
    cf_acq_nol              CHAR(16)    NOT NULL,
    inizio_noleggio         DATE	    NOT NULL,
    fine_noleggio	        DATE        NOT NULL,
    num_serie_stru_nol      CHAR(10)    NOT NULL,
    marca_stru_nol          VARCHAR2(20)    NOT NULL,
    CONSTRAINT pk_nol PRIMARY KEY(cf_acq_nol, num_serie_stru_nol, marca, inizio_noleggio),
    CONSTRAINT fkn1 FOREIGN KEY(cf_acq_nol) REFERENCES acquirente(cf_acq) ON DELETE CASCADE,
    CONSTRAINT fkn2 FOREIGN KEY(num_serie_stru_nol, marca_stru_nol) REFERENCES strumento_negozio(num_serie_stru_neg, marca_stru_neg) ON DELETE CASCADE
);

CREATE TABLE riparazione(
    cod_fattura             NUMBER(5)   PRIMARY KEY,
    tipo_riparazione        VARCHAR2(25),
    data_ricevuta           DATE        NOT NULL,
    data_consegna           DATE,
    cf_richiedente          CHAR(16)    NOT NULL,
    cod_tess_liu_rip        NUMBER(5)   NOT NULL,
    num_serie_rip           CHAR(10)    NOT NULL,
    marca_rip               VARCHAR2(20) NOT NULL,
    costo_rip               NUMBER(5,2)  NOT NULL,
    CONSTRAINT fk_richiedente FOREIGN KEY(cf_richiedente) REFERENCES persona1(cf) ON DELETE CASCADE,
    CONSTRAINT fk_riparatore FOREIGN KEY(cod_tess_liu_rip) REFERENCES liutaio(cod_tess_liu) ON DELETE CASCADE,
    CONSTRAINT fk2_riparazione FOREIGN KEY(num_serie_rip, marca_rip) REFERENCES strumento1(num_serie, marca) ON DELETE CASCADE
);


CREATE TABLE consegna_in_ritardo (
    cod_tracc               CHAR(10)      PRIMARY KEY, 
    inizio_giacenza         DATE          NOT NULL, 
    fine_giacenza           DATE          NOT NULL,
    riconsegna_prevista     DATE          NOT NULL,
    CONSTRAINT giacenza_ok CHECK (fine_giacenza > inizio_giacenza OR fine_giacenza IS NULL)
);

CREATE SEQUENCE add_mese_seq START WITH 1;
CREATE TABLE addetto_del_mese (
    id_add_mese                     NUMBER(3,0)    DEFAULT add_mese_seq.nextval NOT NULL,
    cod_tess_add_mese               NUMBER(5)      NOT NULL,
    no_vendite                      NUMBER(3,0)    NOT NULL,
    fatturato                       NUMBER(5,0)    NOT NULL,
    mese                            VARCHAR2(20)   NOT NULL,
    anno                            NUMBER(4,0)    NOT NULL,
    CONSTRAINT pk_add_mese PRIMARY KEY (id_add_mese)
);
    
