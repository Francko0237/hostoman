--
-- Migration : Module Pharmacie
-- Crée le catalogue de médicaments, les ordonnances/ventes libres
-- et leurs lignes. Lie la table `paiement` aux prescriptions.
--
-- À exécuter dans Supabase SQL Editor.
-- Idempotent (peut être rejoué) : utilise IF NOT EXISTS.
--

BEGIN;

-- =========================================================================
-- 1. Catalogue des médicaments (géré uniquement par la pharmacie)
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.listemedicament (
    id_medicament       bigint      NOT NULL,
    nom_medicament      text        NOT NULL,
    forme               text,                       -- comprimé, sirop, injection, pommade...
    dosage              text,                       -- 500mg, 5%...
    prix_unitaire       real        NOT NULL,
    stock               integer     NOT NULL DEFAULT 0,
    seuil_alerte        integer     NOT NULL DEFAULT 5,
    actif               boolean     NOT NULL DEFAULT true,
    date_enregistrement timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.listemedicament
    ALTER COLUMN id_medicament ADD GENERATED ALWAYS AS IDENTITY (
        SEQUENCE NAME public.listemedicament_id_medicament_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1
    );

ALTER TABLE ONLY public.listemedicament
    ADD CONSTRAINT listemedicament_pkey PRIMARY KEY (id_medicament);

CREATE INDEX IF NOT EXISTS idx_listemedicament_actif
    ON public.listemedicament (actif);

CREATE INDEX IF NOT EXISTS idx_listemedicament_stock_bas
    ON public.listemedicament (stock)
    WHERE actif = true;


-- =========================================================================
-- 2. Prescription (ordonnance médecin OU vente libre pharmacien)
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.prescription (
    id_prescription          bigint NOT NULL,
    id_consultation          bigint,                       -- NULL si vente libre
    id_patient               uuid,                         -- NULL si client de passage
    type_prescription        text   NOT NULL DEFAULT 'consultation',
        -- 'consultation' | 'vente_libre'
    statut_prescription      text   NOT NULL DEFAULT 'en_attente_paiement',
        -- 'en_attente_paiement' | 'paye' | 'partiellement_delivre' | 'delivre' | 'annule'
    total_prix               real   NOT NULL DEFAULT 0,
    date_prescription        timestamp with time zone NOT NULL DEFAULT now(),
    date_derniere_mise_ajour timestamp with time zone,
    CONSTRAINT prescription_type_chk
        CHECK (type_prescription IN ('consultation', 'vente_libre')),
    CONSTRAINT prescription_statut_chk
        CHECK (statut_prescription IN (
            'en_attente_paiement',
            'paye',
            'partiellement_delivre',
            'delivre',
            'annule'
        ))
);

ALTER TABLE public.prescription
    ALTER COLUMN id_prescription ADD GENERATED ALWAYS AS IDENTITY (
        SEQUENCE NAME public.prescription_id_prescription_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1
    );

ALTER TABLE ONLY public.prescription
    ADD CONSTRAINT prescription_pkey PRIMARY KEY (id_prescription);

ALTER TABLE ONLY public.prescription
    ADD CONSTRAINT prescription_id_consultation_fkey
        FOREIGN KEY (id_consultation)
        REFERENCES public."Consultation"(id_consultation)
        ON DELETE SET NULL;

ALTER TABLE ONLY public.prescription
    ADD CONSTRAINT prescription_id_patient_fkey
        FOREIGN KEY (id_patient)
        REFERENCES public."Patient"(id_patient)
        ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_prescription_statut
    ON public.prescription (statut_prescription);

CREATE INDEX IF NOT EXISTS idx_prescription_date
    ON public.prescription (date_prescription);

CREATE INDEX IF NOT EXISTS idx_prescription_consultation
    ON public.prescription (id_consultation);


-- =========================================================================
-- 3. Lignes de prescription (1 ligne = 1 médicament prescrit)
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.prescription_ligne (
    id_ligne                bigint  NOT NULL,
    id_prescription         bigint  NOT NULL,
    id_medicament           bigint,                  -- NULL si saisie libre du médecin
    id_medicament_substitut bigint,                  -- NULL sauf substitution par pharmacien
    nom_medicament          text    NOT NULL,        -- snapshot ou texte libre
    posologie               text    NOT NULL,
    quantite                integer NOT NULL DEFAULT 1,
    prix_unitaire           real,                    -- snapshot, NULL tant que pharmacien n'a pas saisi (cas saisie libre)
    disponible_initialement boolean,                 -- état au moment de la prescription
    statut_ligne            text    NOT NULL DEFAULT 'en_attente',
        -- 'en_attente' | 'delivre' | 'rupture' | 'substitue' | 'annule'
    CONSTRAINT prescription_ligne_quantite_chk CHECK (quantite > 0),
    CONSTRAINT prescription_ligne_statut_chk CHECK (statut_ligne IN (
        'en_attente', 'delivre', 'rupture', 'substitue', 'annule'
    ))
);

ALTER TABLE public.prescription_ligne
    ALTER COLUMN id_ligne ADD GENERATED ALWAYS AS IDENTITY (
        SEQUENCE NAME public.prescription_ligne_id_ligne_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1
    );

ALTER TABLE ONLY public.prescription_ligne
    ADD CONSTRAINT prescription_ligne_pkey PRIMARY KEY (id_ligne);

ALTER TABLE ONLY public.prescription_ligne
    ADD CONSTRAINT prescription_ligne_id_prescription_fkey
        FOREIGN KEY (id_prescription)
        REFERENCES public.prescription(id_prescription)
        ON DELETE CASCADE;

ALTER TABLE ONLY public.prescription_ligne
    ADD CONSTRAINT prescription_ligne_id_medicament_fkey
        FOREIGN KEY (id_medicament)
        REFERENCES public.listemedicament(id_medicament)
        ON DELETE SET NULL;

ALTER TABLE ONLY public.prescription_ligne
    ADD CONSTRAINT prescription_ligne_id_medicament_substitut_fkey
        FOREIGN KEY (id_medicament_substitut)
        REFERENCES public.listemedicament(id_medicament)
        ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_prescription_ligne_prescription
    ON public.prescription_ligne (id_prescription);

CREATE INDEX IF NOT EXISTS idx_prescription_ligne_statut
    ON public.prescription_ligne (statut_ligne);


-- =========================================================================
-- 4. Lien paiement -> prescription
--    On ajoute simplement la colonne `id_prescription` à `paiement`.
--    Le motif reste 'Medicaments' pour ce type de paiement.
-- =========================================================================
ALTER TABLE public.paiement
    ADD COLUMN IF NOT EXISTS id_prescription bigint;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'paiement_id_prescription_fkey'
    ) THEN
        ALTER TABLE ONLY public.paiement
            ADD CONSTRAINT paiement_id_prescription_fkey
                FOREIGN KEY (id_prescription)
                REFERENCES public.prescription(id_prescription)
                ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_paiement_id_prescription
    ON public.paiement (id_prescription);


-- =========================================================================
-- 5. Trigger : recalcul automatique du statut global d'une prescription
--    quand le statut d'une ligne change.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.recalc_prescription_statut()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_lignes int;
    v_lignes_delivrees int;
    v_lignes_en_attente int;
    v_statut_actuel text;
    v_id_prescription bigint;
BEGIN
    v_id_prescription := COALESCE(NEW.id_prescription, OLD.id_prescription);

    SELECT statut_prescription INTO v_statut_actuel
    FROM public.prescription
    WHERE id_prescription = v_id_prescription;

    -- On ne touche pas aux prescriptions déjà annulées
    IF v_statut_actuel = 'annule' THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    SELECT
        count(*),
        count(*) FILTER (WHERE statut_ligne IN ('delivre', 'substitue')),
        count(*) FILTER (WHERE statut_ligne = 'en_attente')
    INTO v_total_lignes, v_lignes_delivrees, v_lignes_en_attente
    FROM public.prescription_ligne
    WHERE id_prescription = v_id_prescription;

    IF v_total_lignes = 0 THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- Toutes les lignes sont délivrées (ou substituées)
    IF v_lignes_delivrees = v_total_lignes THEN
        UPDATE public.prescription
        SET statut_prescription = 'delivre',
            date_derniere_mise_ajour = now()
        WHERE id_prescription = v_id_prescription
          AND statut_prescription <> 'delivre';

    -- Au moins une délivrée mais pas toutes
    ELSIF v_lignes_delivrees > 0 AND v_lignes_en_attente >= 0 THEN
        UPDATE public.prescription
        SET statut_prescription = 'partiellement_delivre',
            date_derniere_mise_ajour = now()
        WHERE id_prescription = v_id_prescription
          AND statut_prescription IN ('paye', 'en_attente_paiement');
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_recalc_prescription_statut ON public.prescription_ligne;
CREATE TRIGGER trg_recalc_prescription_statut
AFTER INSERT OR UPDATE OF statut_ligne OR DELETE
ON public.prescription_ligne
FOR EACH ROW
EXECUTE FUNCTION public.recalc_prescription_statut();


-- =========================================================================
-- 6. Fonction utilitaire : annulation des prescriptions impayées
--    périmées (à appeler à l'ouverture de la pharmacie chaque jour).
--    Annule aussi le paiement associé.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.annuler_prescriptions_perimees()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_count integer;
BEGIN
    WITH expirees AS (
        UPDATE public.prescription
        SET statut_prescription = 'annule',
            date_derniere_mise_ajour = now()
        WHERE statut_prescription = 'en_attente_paiement'
          AND date_prescription::date < CURRENT_DATE
        RETURNING id_prescription
    )
    UPDATE public.paiement p
    SET statut_paiement = 'annule',
        date_paiement = COALESCE(p.date_paiement, now())
    FROM expirees e
    WHERE p.id_prescription = e.id_prescription
      AND p.statut_paiement = 'en_attente';

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


-- =========================================================================
-- 7. Fonction utilitaire : décrément stock à la délivrance d'une ligne
--    (à appeler côté app après marquage 'delivre' ou 'substitue').
--    Utile pour garder l'opération atomique côté SQL.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.delivrer_ligne_prescription(
    p_id_ligne bigint,
    p_id_medicament_substitut bigint DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_quantite int;
    v_id_med bigint;
    v_stock int;
BEGIN
    SELECT quantite,
           COALESCE(p_id_medicament_substitut, id_medicament)
    INTO v_quantite, v_id_med
    FROM public.prescription_ligne
    WHERE id_ligne = p_id_ligne
    FOR UPDATE;

    IF v_id_med IS NOT NULL THEN
        SELECT stock INTO v_stock
        FROM public.listemedicament
        WHERE id_medicament = v_id_med
        FOR UPDATE;

        IF v_stock < v_quantite THEN
            RAISE EXCEPTION 'Stock insuffisant pour le médicament %', v_id_med;
        END IF;

        UPDATE public.listemedicament
        SET stock = stock - v_quantite
        WHERE id_medicament = v_id_med;
    END IF;

    IF p_id_medicament_substitut IS NOT NULL THEN
        UPDATE public.prescription_ligne
        SET id_medicament_substitut = p_id_medicament_substitut,
            statut_ligne = 'substitue'
        WHERE id_ligne = p_id_ligne;
    ELSE
        UPDATE public.prescription_ligne
        SET statut_ligne = 'delivre'
        WHERE id_ligne = p_id_ligne;
    END IF;
END;
$$;


COMMIT;
