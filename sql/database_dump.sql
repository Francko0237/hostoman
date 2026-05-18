--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public."Parametres_vitaux" DROP CONSTRAINT IF EXISTS parametres_vitaux_id_personnel_fkey;
ALTER TABLE IF EXISTS ONLY public.paiement DROP CONSTRAINT IF EXISTS paiement_id_consultation_fkey;
ALTER TABLE IF EXISTS ONLY public.examen_a_effectuer DROP CONSTRAINT IF EXISTS examen_a_effecuer_id_consultation_fkey;
ALTER TABLE IF EXISTS ONLY public."Consultation" DROP CONSTRAINT IF EXISTS consultation_id_personnel_fkey;
ALTER TABLE IF EXISTS ONLY public."Parametres_vitaux" DROP CONSTRAINT IF EXISTS "Parametres_vitaux_id_patient_fkey";
ALTER TABLE IF EXISTS ONLY public."Consultation" DROP CONSTRAINT IF EXISTS "Consultation_id_patient_fkey";
ALTER TABLE IF EXISTS ONLY public."Consultation" DROP CONSTRAINT IF EXISTS "Consultation_id_parametres_vitaux_fkey";
ALTER TABLE IF EXISTS ONLY public."Personnel_hopital" DROP CONSTRAINT IF EXISTS personnel_hopital_pkey;
ALTER TABLE IF EXISTS ONLY public."Patient" DROP CONSTRAINT IF EXISTS patient_pkey;
ALTER TABLE IF EXISTS ONLY public."Parametres_vitaux" DROP CONSTRAINT IF EXISTS parametres_vitaux_pkey;
ALTER TABLE IF EXISTS ONLY public.paiement DROP CONSTRAINT IF EXISTS paiement_pkey;
ALTER TABLE IF EXISTS ONLY public.listeexamen DROP CONSTRAINT IF EXISTS listeexamen_pkey;
ALTER TABLE IF EXISTS ONLY public.examen_a_effectuer DROP CONSTRAINT IF EXISTS examen_a_effectuer_pkey;
ALTER TABLE IF EXISTS ONLY public."Consultation" DROP CONSTRAINT IF EXISTS consultation_pkey;
DROP TABLE IF EXISTS public.paiement;
DROP TABLE IF EXISTS public.listeexamen;
DROP TABLE IF EXISTS public.examen_a_effectuer;
DROP TABLE IF EXISTS public."Personnel_hopital";
DROP TABLE IF EXISTS public."Patient";
DROP TABLE IF EXISTS public."Parametres_vitaux";
DROP TABLE IF EXISTS public."Consultation";
DROP FUNCTION IF EXISTS public.delete_personnel_auth_user(p_id uuid);
DROP FUNCTION IF EXISTS public.create_personnel_auth_user(p_email text, p_password text);
DROP SCHEMA IF EXISTS public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: create_personnel_auth_user(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_personnel_auth_user(p_email text, p_password text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_id uuid := gen_random_uuid();
begin
  -- Vérifie que l'email n'existe pas déjà
  if exists (select 1 from auth.users where email = p_email) then
    raise exception 'EMAIL_ALREADY_EXISTS';
  end if;

  insert into auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    is_super_admin,
    confirmation_token
  ) values (
    v_id,
    '00000000-0000-0000-0000-000000000000',
    p_email,
    extensions.crypt(p_password, extensions.gen_salt('bf')),  -- ✅ Correction ici : on préfixe par extensions.
    now(),                              
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    'authenticated',
    'authenticated',
    false,
    ''
  );

  return v_id;
end;
$$;


--
-- Name: delete_personnel_auth_user(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_personnel_auth_user(p_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  delete from auth.users where id = p_id;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Consultation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Consultation" (
    id_consultation bigint NOT NULL,
    date_enregistrement timestamp with time zone NOT NULL,
    id_patient uuid DEFAULT gen_random_uuid(),
    id_parametres_vitaux bigint,
    "Statut_Consultation" text,
    type_service text,
    id_personnel uuid,
    antecedents text,
    signes_symptomes text,
    diagnostic_initial text,
    diagnostic_final text,
    traitement_prescrit text,
    programmation_rdv text,
    date_rdv_prevu timestamp with time zone,
    date_derniere_mise_ajour timestamp with time zone
);


--
-- Name: Parametres_vitaux; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Parametres_vitaux" (
    id_parametres_vitaux bigint NOT NULL,
    temperature real NOT NULL,
    poid real,
    systolique real,
    diastolique real,
    "statut_VIH" text,
    vaccination text,
    id_patient uuid DEFAULT gen_random_uuid(),
    date_enregistrement timestamp with time zone,
    type_service text,
    motif_de_consultation text,
    id_personnel uuid
);


--
-- Name: Patient; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Patient" (
    id_patient uuid DEFAULT gen_random_uuid() NOT NULL,
    nom_complet text NOT NULL,
    sexe text NOT NULL,
    age integer NOT NULL,
    telephone bigint,
    adresse text,
    profession text,
    statut_matrimonial text,
    date_enregistrement timestamp with time zone
);


--
-- Name: Personnel_hopital; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Personnel_hopital" (
    id_personnel uuid DEFAULT gen_random_uuid() NOT NULL,
    "Nom" text NOT NULL,
    "Prenom" text,
    date_enregistrement timestamp with time zone,
    "Specialite" text,
    telephone integer,
    email text,
    age integer,
    adresse text,
    sexe text,
    es_medecin boolean
);


--
-- Name: consultation_id_consultation_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public."Consultation" ALTER COLUMN id_consultation ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.consultation_id_consultation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: examen_a_effectuer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.examen_a_effectuer (
    id_examen bigint NOT NULL,
    nom_examen text NOT NULL,
    statut_examen text,
    id_consultation bigint,
    prix_examen real,
    date_enregistrement timestamp with time zone,
    resultat_examen text
);


--
-- Name: examen_a_effectuer_id_examen_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.examen_a_effectuer ALTER COLUMN id_examen ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.examen_a_effectuer_id_examen_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: listeexamen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listeexamen (
    id_examlist bigint NOT NULL,
    date_enregistrement timestamp with time zone DEFAULT now() NOT NULL,
    nom_examen text,
    prix_examen real
);


--
-- Name: listeexamen_id_examlist_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.listeexamen ALTER COLUMN id_examlist ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.listeexamen_id_examlist_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: paiement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paiement (
    id_paiement bigint NOT NULL,
    date_paiement timestamp with time zone NOT NULL,
    motif text,
    prix_a_paye real,
    statut_paiement text,
    id_consultation bigint
);


--
-- Name: paiement_id_paiement_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.paiement ALTER COLUMN id_paiement ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.paiement_id_paiement_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: parametres_vitaux_id_parametres_vitaux_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public."Parametres_vitaux" ALTER COLUMN id_parametres_vitaux ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.parametres_vitaux_id_parametres_vitaux_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: Consultation; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (21, '2026-02-23 12:35:30.371534+00', '4c8c23e3-3bb1-4e32-8d2e-ca96c6e1f4a2', 34, 'terminer', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'fddfsdfdsfdsf', 'dsfdsfs', 'dsf', 'sdcds', 'wxcxwc', NULL, NULL, '2026-02-23 12:44:25.500121+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (24, '2026-03-19 19:56:02.177765+00', '6fa16aa9-b8b6-4ed6-98f1-cc3aeb55e8d3', 37, 'terminer', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'sdf', 'sdf', 'sfd', 'sdf', 'sdf', NULL, NULL, '2026-03-19 20:13:51.316227+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (22, '2026-03-10 17:01:14.594925+00', '24134863-2a9d-49f4-a146-bc1c58cdf69d', 35, 'terminer', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'sdf', 'sdf', 'dsf', 'ERT', 'S', NULL, NULL, '2026-03-19 20:14:04.80147+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (23, '2026-03-17 16:53:44.302939+00', 'ac36a29d-ee6c-4fdd-abd8-7d41ed86c409', 36, 'resultat-disponible', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'dsf', 'sdf', 'sdfdsf', 'fsd', 'qsd', NULL, NULL, '2026-03-30 10:47:31.886512+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (25, '2026-03-28 03:52:27.25291+00', '880223ee-8103-4611-aed0-acee880eb4cc', 38, 'resultat-disponible', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'qsf', 'sdf', 'sdf', 'sdf', 'sdf', NULL, NULL, '2026-03-30 10:53:48.716885+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (26, '2026-03-30 11:03:24.640487+00', 'd5a03ff7-887d-45c7-a313-18b97d727ed6', 39, 'en-attente-examen', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'Bdsh', 'Bd', 'Sh', 'D', 'Jdj', NULL, NULL, '2026-03-30 11:39:19.609689+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (27, '2026-03-31 09:40:20.286859+00', 'fcd97bbe-6626-4357-ad74-aec81166fa6d', 40, 'en-attente-consultation', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-31 09:40:20.286978+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (29, '2026-04-07 14:58:52.636296+00', '547e1195-3c7c-4093-8663-e7189ce6d9bc', 42, 'en-attente-consultation', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-07 14:58:52.636373+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (28, '2026-04-07 14:17:27.519463+00', 'f1fedd6d-6cbd-4518-b992-730cf04667b1', 41, 'resultat-disponible', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'rdrd', 'dtf', 'rtyguu', 'tdfg', 'tfghjj', NULL, NULL, '2026-04-07 15:19:41.397787+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (20, '2026-02-16 07:59:25.319889+00', '2bd1a033-e2f2-4be6-bf40-4fc9bca1b0b1', 33, 'en-attente-consultation', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-16 07:59:25.319957+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (19, '2026-02-16 07:54:18.361583+00', '2bd1a033-e2f2-4be6-bf40-4fc9bca1b0b1', 32, 'en-attente-examen', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'Ras', 'Température élevé ', 'Ldkd', 'Unwn', '''w'' s', NULL, NULL, '2026-02-16 16:17:57.804215+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (16, '2026-02-16 07:49:26.012815+00', '24134863-2a9d-49f4-a146-bc1c58cdf69d', 29, 'terminer', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'Ujj', 'Vbhyy', 'Vvv', 'Bbb', 'Jj', 'RDV_programmer', '2026-02-17 03:42:00+00', '2026-02-16 16:42:17.97434+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (18, '2026-02-16 07:52:50.663545+00', '3db12e7c-e69e-4658-9ec1-9da22dbdfc6d', 31, 'terminer', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'Ujss', 'Bsbs', 'Shhs', 'Bbb', 'Bjj', NULL, NULL, '2026-02-16 17:07:01.816197+00');
INSERT INTO public."Consultation" (id_consultation, date_enregistrement, id_patient, id_parametres_vitaux, "Statut_Consultation", type_service, id_personnel, antecedents, signes_symptomes, diagnostic_initial, diagnostic_final, traitement_prescrit, programmation_rdv, date_rdv_prevu, date_derniere_mise_ajour) VALUES (17, '2026-02-16 07:51:26.944822+00', 'd27bc58d-5f90-472a-9601-6983d9c7921d', 30, 'resultat-disponible', 'Consultation', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'Vvhhh', 'Vv', 'Vv', 'Bv', 'Yg', NULL, NULL, '2026-02-16 17:07:45.153011+00');


--
-- Data for Name: Parametres_vitaux; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (29, 38, 75, 120, 80, 'INE', 'Non', '24134863-2a9d-49f4-a146-bc1c58cdf69d', '2026-02-16 07:49:25.938865+00', 'Consultation', 'Mal de tête', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (30, 38, 80, 120, 80, 'INE', 'Non', 'd27bc58d-5f90-472a-9601-6983d9c7921d', '2026-02-16 07:51:26.922235+00', 'Consultation', 'Mal de ventre', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (31, 38, 70, 120, 80, 'INE', 'Non', '3db12e7c-e69e-4658-9ec1-9da22dbdfc6d', '2026-02-16 07:52:50.651926+00', 'Consultation', 'Douleur musculaire', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (32, 37.5, 85, 120, 80, 'Négatif', 'Non', '2bd1a033-e2f2-4be6-bf40-4fc9bca1b0b1', '2026-02-16 07:54:18.339309+00', 'Consultation', 'Douleur musculaire', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (33, 37.5, 88, 120, 80, 'Négatif', 'Non', '2bd1a033-e2f2-4be6-bf40-4fc9bca1b0b1', '2026-02-16 07:59:25.295547+00', 'Consultation', 'Mal de dos', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (34, 38, 67, 120, 80, 'Negative', 'NOn', '4c8c23e3-3bb1-4e32-8d2e-ca96c6e1f4a2', '2026-02-23 12:35:30.346419+00', 'Consultation', 'ytfjkl', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (35, 37, 50, 120, 80, 'INE', 'Non', '24134863-2a9d-49f4-a146-bc1c58cdf69d', '2026-03-10 17:01:14.587508+00', 'Consultation', 'Mal de tête', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (36, 37, 70, 120, 80, 'Négatif', 'INE', 'ac36a29d-ee6c-4fdd-abd8-7d41ed86c409', '2026-03-17 16:53:44.255519+00', 'Consultation', 'Non', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (37, 37, 73, 120, 80, 'Négatif', 'Non', '6fa16aa9-b8b6-4ed6-98f1-cc3aeb55e8d3', '2026-03-19 19:56:02.167704+00', 'Consultation', 'Mal de tête', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (38, 37, 80, 120, 80, 'NON', 'NON', '880223ee-8103-4611-aed0-acee880eb4cc', '2026-03-28 03:52:27.226324+00', 'Consultation', 'NO', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (39, 33, 70, 120, 80, 'nin', 'INVALIDE', 'd5a03ff7-887d-45c7-a313-18b97d727ed6', '2026-03-30 11:03:24.583829+00', 'Consultation', 'RAS', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (40, 37, 70, 120, 80, 'non', 'inconnue', 'fcd97bbe-6626-4357-ad74-aec81166fa6d', '2026-03-31 09:40:20.255311+00', 'Consultation', 'shjdkqlfd', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (41, 37, 70, 120, 80, 'INE', 'Non', 'f1fedd6d-6cbd-4518-b992-730cf04667b1', '2026-04-07 14:17:27.488401+00', 'Consultation', 'Mal de tête', '960da502-2ea7-485d-945e-2c4613553eb7');
INSERT INTO public."Parametres_vitaux" (id_parametres_vitaux, temperature, poid, systolique, diastolique, "statut_VIH", vaccination, id_patient, date_enregistrement, type_service, motif_de_consultation, id_personnel) VALUES (42, 37, 70, 120, 80, 'INE', 'NON', '547e1195-3c7c-4093-8663-e7189ce6d9bc', '2026-04-07 14:58:52.613259+00', 'Consultation', 'Mal de tete', '960da502-2ea7-485d-945e-2c4613553eb7');


--
-- Data for Name: Patient; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('d27bc58d-5f90-472a-9601-6983d9c7921d', 'Daniella', 'Femme', 25, 677556837, 'Pk-8', 'Couturière', 'Concubinage', '2026-02-16 07:51:26.88189+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('3db12e7c-e69e-4658-9ec1-9da22dbdfc6d', 'Damso', 'Homme', 19, 670870367, 'Nkoalong', 'Étudiant', 'Célibataire', '2026-02-16 07:52:50.641433+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('2bd1a033-e2f2-4be6-bf40-4fc9bca1b0b1', 'Ngonsomors Julio Alain', 'Homme', 38, 670619582, 'Manjo quartier 2', 'Entrepreneur', 'Marié Polygame', '2026-02-16 07:59:25.233488+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('4c8c23e3-3bb1-4e32-8d2e-ca96c6e1f4a2', 'Nom', 'Homme', 23, 345789, 'fjnkj', 'jvvj', 'Célibataire', '2026-02-23 12:35:30.33792+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('24134863-2a9d-49f4-a146-bc1c58cdf69d', 'Yamga', 'Homme', 25, 6706789, 'Douala,PK-14', 'Etudiant', 'Concubinage', '2026-03-17 14:45:03.805185+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('ac36a29d-ee6c-4fdd-abd8-7d41ed86c409', 'Kamdem', 'Homme', 19, 6706777098789, 'Pk-14', 'Etudiant', 'Célibataire', '2026-03-17 16:53:44.23924+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('6fa16aa9-b8b6-4ed6-98f1-cc3aeb55e8d3', 'Dassi', 'Homme', 19, 677426534, 'Douala', 'Etudiant', 'Célibataire', '2026-03-19 19:56:02.129304+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('880223ee-8103-4611-aed0-acee880eb4cc', 'Dans', 'Homme', 23, 4563456789, 'Manjo', 'Etudiant', 'Concubinage', '2026-03-28 03:52:27.183398+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('d5a03ff7-887d-45c7-a313-18b97d727ed6', 'fRESH', 'Homme', 33, 44444444444444, 'efzz', 'erg', 'Concubinage', '2026-03-30 11:03:24.57532+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('fcd97bbe-6626-4357-ad74-aec81166fa6d', 'Dns', 'Femme', 32, 678906789, 'pk-12', 'etudiante', 'Concubinage', '2026-04-01 08:19:40.596326+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('f1fedd6d-6cbd-4518-b992-730cf04667b1', 'Kamga Franck', 'Homme', 21, 670619582, 'Pk-14', 'Etudiant', 'Célibataire', '2026-04-07 14:17:27.480084+00');
INSERT INTO public."Patient" (id_patient, nom_complet, sexe, age, telephone, adresse, profession, statut_matrimonial, date_enregistrement) VALUES ('547e1195-3c7c-4093-8663-e7189ce6d9bc', 'Yamga Franck', 'Homme', 25, 670619582, 'pk-14', 'Etudiant', 'Célibataire', '2026-04-07 14:59:24.385396+00');


--
-- Data for Name: Personnel_hopital; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Personnel_hopital" (id_personnel, "Nom", "Prenom", date_enregistrement, "Specialite", telephone, email, age, adresse, sexe, es_medecin) VALUES ('1976b828-a5ef-48d2-adc1-707d4e83ede2', 'Yamga Mokube', 'Francko Daniel', '2025-12-07 01:04:03+00', 'Directeur', 670619582, 'danielfrancko215@gmail.com', 19, 'PK-14', 'Homme', NULL);
INSERT INTO public."Personnel_hopital" (id_personnel, "Nom", "Prenom", date_enregistrement, "Specialite", telephone, email, age, adresse, sexe, es_medecin) VALUES ('960da502-2ea7-485d-945e-2c4613553eb7', 'Manfo', 'Jordan', '2025-10-18 17:42:39+00', 'Major Accueil', 672523344, 'jordanmanfo@gmail.com', 22, 'Quartier 1', 'Homme', false);
INSERT INTO public."Personnel_hopital" (id_personnel, "Nom", "Prenom", date_enregistrement, "Specialite", telephone, email, age, adresse, sexe, es_medecin) VALUES ('0a7c8648-f7d2-43d0-abd4-6d8926199831', 'Sime', 'Yves', '2025-10-18 14:38:19+00', 'Médecin Généraliste', 333, 'sdsd', 33, 'Quartier 2', 'M', true);
INSERT INTO public."Personnel_hopital" (id_personnel, "Nom", "Prenom", date_enregistrement, "Specialite", telephone, email, age, adresse, sexe, es_medecin) VALUES ('95999340-b964-429b-9750-2ec86d656fb8', 'Schansli', 'Tekom', '2026-04-02 09:37:53.11943+00', 'Laborantin', 679282772, 'labo@gmail.com', 32, 'quartier 1', 'Homme', NULL);
INSERT INTO public."Personnel_hopital" (id_personnel, "Nom", "Prenom", date_enregistrement, "Specialite", telephone, email, age, adresse, sexe, es_medecin) VALUES ('2efccfdb-cdd0-4418-aecb-0351727564ed', 'Dimeli', 'Christian', '2025-10-31 09:53:19+00', 'Caissier', 670536720, 'dimelichristian@gmail.com', 21, 'Quartier 1', 'Homme', false);


--
-- Data for Name: examen_a_effectuer; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (50, 'Échographie Abdominale', 'Terminé', 23, 15000, '2026-03-17 17:04:12.142191+00', 'htt');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (51, 'Glycémie à jeun', 'Terminé', 23, 2000, '2026-03-17 17:04:12.142191+00', 'hh');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (52, 'Hémogramme (NFS)', 'Terminé', 23, 3500, '2026-03-17 17:04:12.142191+00', 'hy');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (53, 'Radiographie (Poumons)', 'Terminé', 23, 8000, '2026-03-17 17:04:12.142191+00', 'hy');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (54, 'Selles (coproculture)', 'Terminé', 23, 3000, '2026-03-17 17:04:12.142191+00', 'hy');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (55, 'Créatinine', 'Annulé', 25, 2500, '2026-03-28 18:07:45.969393+00', NULL);
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (56, 'Échographie Abdominale', 'Terminé', 25, 15000, '2026-03-28 18:07:45.969393+00', 'yj');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (57, 'Glycémie à jeun', 'Terminé', 25, 2000, '2026-03-28 18:07:45.969393+00', 'yj');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (58, 'Hémogramme (NFS)', 'Terminé', 25, 3500, '2026-03-28 18:07:45.969393+00', 'jy');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (59, 'Créatinine', 'en attente', 26, 2500, '2026-03-30 11:39:19.609689+00', NULL);
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (60, 'Glycémie à jeun', 'en attente', 26, 2000, '2026-03-30 11:39:19.609689+00', NULL);
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (42, 'Créatinine', 'en attente', 19, 2500, '2026-02-16 16:17:57.804215+00', NULL);
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (43, 'Échographie Abdominale', 'en attente', 19, 15000, '2026-02-16 16:17:57.804215+00', NULL);
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (61, 'Créatinine', 'Terminé', 28, 2500, '2026-04-07 15:06:42.481+00', '23');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (62, 'Échographie Abdominale', 'Terminé', 28, 15000, '2026-04-07 15:06:42.481+00', '34');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (44, 'Créatinine', 'Terminé', 18, 2500, '2026-02-16 16:40:35.51005+00', 'Hdhs');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (45, 'Échographie Abdominale', 'Terminé', 18, 15000, '2026-02-16 16:40:35.51005+00', 'Ndbd');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (46, 'Glycémie à jeun', 'Terminé', 17, 2000, '2026-02-16 16:41:24.537402+00', 'Jdj');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (47, 'Hémogramme (NFS)', 'Terminé', 17, 3500, '2026-02-16 16:41:24.537402+00', 'Nwns');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (48, 'Créatinine', 'Terminé', 21, 2500, '2026-02-23 12:41:05.562742+00', 'rgdsg');
INSERT INTO public.examen_a_effectuer (id_examen, nom_examen, statut_examen, id_consultation, prix_examen, date_enregistrement, resultat_examen) OVERRIDING SYSTEM VALUE VALUES (49, 'Échographie Abdominale', 'Terminé', 21, 15000, '2026-02-23 12:41:05.562742+00', 'wfd');


--
-- Data for Name: listeexamen; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (1, '2025-12-04 01:39:46.170688+00', 'Hémogramme (NFS)', 3500);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (2, '2025-12-04 01:39:46.170688+00', 'Glycémie à jeun', 2000);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (3, '2025-12-04 01:39:46.170688+00', 'Urine (ECBU)', 2500);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (4, '2025-12-04 01:39:46.170688+00', 'Selles (coproculture)', 3000);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (5, '2025-12-04 01:39:46.170688+00', 'Créatinine', 2500);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (6, '2025-12-04 01:39:46.170688+00', 'Transaminases (ALAT/ASAT)', 4000);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (7, '2025-12-04 01:39:46.170688+00', 'Sérologie VIH', 3000);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (8, '2025-12-04 01:39:46.170688+00', 'Sérologie Paludisme', 2000);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (9, '2025-12-04 01:39:46.170688+00', 'Radiographie (Poumons)', 8000);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (10, '2025-12-04 01:39:46.170688+00', 'Échographie Abdominale', 15000);
INSERT INTO public.listeexamen (id_examlist, date_enregistrement, nom_examen, prix_examen) OVERRIDING SYSTEM VALUE VALUES (11, '2025-12-04 01:39:46.170688+00', 'TDR Paludisme', 1500);


--
-- Data for Name: paiement; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (38, '2026-03-19 19:56:02.207536+00', 'Consultation', 600, 'payer', 24);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (35, '2026-03-10 17:01:14.611796+00', 'Consultation', 600, 'payer', 22);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (39, '2026-03-28 03:52:27.26418+00', 'Consultation', 600, 'payer', 25);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (40, '2026-03-28 18:07:45.969393+00', 'Examens', 23000, 'payer', 25);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (41, '2026-03-30 11:03:24.649912+00', 'Consultation', 600, 'payer', 26);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (42, '2026-03-30 11:39:19.609689+00', 'Examens', 4500, 'payer', 26);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (43, '2026-03-31 09:40:20.309515+00', 'Consultation', 600, 'payer', 27);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (45, '2026-04-07 14:58:52.645967+00', 'Consultation', 600, 'payer', 29);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (44, '2026-04-07 14:17:27.537637+00', 'Consultation', 600, 'payer', 28);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (46, '2026-04-07 15:06:42.481+00', 'Examens', 17500, 'payer', 28);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (29, '2026-02-16 07:59:25.343928+00', 'Consultation', 600, 'annuler', 20);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (25, '2026-02-16 07:49:26.029667+00', 'Consultation', 600, 'payer', 16);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (26, '2026-02-16 07:51:26.955308+00', 'Consultation', 600, 'payer', 17);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (32, '2026-02-16 16:41:24.537402+00', 'Examens', 5500, 'payer', 17);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (27, '2026-02-16 07:52:50.676796+00', 'Consultation', 600, 'payer', 18);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (31, '2026-02-16 16:40:35.51005+00', 'Examens', 17500, 'payer', 18);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (28, '2026-02-16 07:54:18.375578+00', 'Consultation', 600, 'annuler', 19);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (30, '2026-02-16 16:17:57.804215+00', 'Examens', 4000, 'annuler', 19);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (33, '2026-02-23 12:35:30.381226+00', 'Consultation', 600, 'payer', 21);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (34, '2026-02-23 12:41:05.562742+00', 'Examens', 17500, 'payer', 21);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (36, '2026-03-17 16:53:44.336444+00', 'Consultation', 600, 'payer', 23);
INSERT INTO public.paiement (id_paiement, date_paiement, motif, prix_a_paye, statut_paiement, id_consultation) OVERRIDING SYSTEM VALUE VALUES (37, '2026-03-17 17:04:12.142191+00', 'Examens', 31500, 'payer', 23);


--
-- Name: consultation_id_consultation_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consultation_id_consultation_seq', 29, true);


--
-- Name: examen_a_effectuer_id_examen_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.examen_a_effectuer_id_examen_seq', 62, true);


--
-- Name: listeexamen_id_examlist_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.listeexamen_id_examlist_seq', 11, true);


--
-- Name: paiement_id_paiement_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.paiement_id_paiement_seq', 46, true);


--
-- Name: parametres_vitaux_id_parametres_vitaux_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.parametres_vitaux_id_parametres_vitaux_seq', 42, true);


--
-- Name: Consultation consultation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Consultation"
    ADD CONSTRAINT consultation_pkey PRIMARY KEY (id_consultation);


--
-- Name: examen_a_effectuer examen_a_effectuer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.examen_a_effectuer
    ADD CONSTRAINT examen_a_effectuer_pkey PRIMARY KEY (id_examen);


--
-- Name: listeexamen listeexamen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listeexamen
    ADD CONSTRAINT listeexamen_pkey PRIMARY KEY (id_examlist);


--
-- Name: paiement paiement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paiement
    ADD CONSTRAINT paiement_pkey PRIMARY KEY (id_paiement);


--
-- Name: Parametres_vitaux parametres_vitaux_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Parametres_vitaux"
    ADD CONSTRAINT parametres_vitaux_pkey PRIMARY KEY (id_parametres_vitaux);


--
-- Name: Patient patient_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Patient"
    ADD CONSTRAINT patient_pkey PRIMARY KEY (id_patient);


--
-- Name: Personnel_hopital personnel_hopital_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Personnel_hopital"
    ADD CONSTRAINT personnel_hopital_pkey PRIMARY KEY (id_personnel);


--
-- Name: Consultation Consultation_id_parametres_vitaux_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Consultation"
    ADD CONSTRAINT "Consultation_id_parametres_vitaux_fkey" FOREIGN KEY (id_parametres_vitaux) REFERENCES public."Parametres_vitaux"(id_parametres_vitaux) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Consultation Consultation_id_patient_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Consultation"
    ADD CONSTRAINT "Consultation_id_patient_fkey" FOREIGN KEY (id_patient) REFERENCES public."Patient"(id_patient) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Parametres_vitaux Parametres_vitaux_id_patient_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Parametres_vitaux"
    ADD CONSTRAINT "Parametres_vitaux_id_patient_fkey" FOREIGN KEY (id_patient) REFERENCES public."Patient"(id_patient) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Consultation consultation_id_personnel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Consultation"
    ADD CONSTRAINT consultation_id_personnel_fkey FOREIGN KEY (id_personnel) REFERENCES public."Personnel_hopital"(id_personnel);


--
-- Name: examen_a_effectuer examen_a_effecuer_id_consultation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.examen_a_effectuer
    ADD CONSTRAINT examen_a_effecuer_id_consultation_fkey FOREIGN KEY (id_consultation) REFERENCES public."Consultation"(id_consultation);


--
-- Name: paiement paiement_id_consultation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paiement
    ADD CONSTRAINT paiement_id_consultation_fkey FOREIGN KEY (id_consultation) REFERENCES public."Consultation"(id_consultation) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Parametres_vitaux parametres_vitaux_id_personnel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Parametres_vitaux"
    ADD CONSTRAINT parametres_vitaux_id_personnel_fkey FOREIGN KEY (id_personnel) REFERENCES public."Personnel_hopital"(id_personnel);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '1976b828-a5ef-48d2-adc1-707d4e83ede2', 'authenticated', 'authenticated', 'admin@gmail.com', '$2a$10$FDpGmHxhLyESRq7MKEPN4ufXqFByAX5Ae3OY6pR0YWD.dDjsaDDfS', '2026-02-01 05:41:20.153978+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-04-07 14:35:44.287529+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2026-02-01 05:41:20.15269+00', '2026-04-07 14:35:44.288618+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '95999340-b964-429b-9750-2ec86d656fb8', 'authenticated', 'authenticated', 'labo@gmail.com', '$2a$10$GaoCjUpMrjVIRmwrFiKlvuANWhhjAvDOaIlPU.PIKvt8WP4ccLf22', '2026-04-02 08:37:53.112147+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-04-07 14:08:56.800835+00', '{"provider": "email", "providers": ["email"]}', '{"Specialite": "Laborantin", "email_verified": true}', NULL, '2026-04-02 08:37:53.110262+00', '2026-04-09 04:50:58.115693+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'dc7445e5-f7e8-4065-b127-7c727d3b9a8f', 'authenticated', 'authenticated', 'test_rpc_1775116622765@example.com', '$2a$06$Wf.FjdGsNy4RIG4mVfFTn.K8BXIiQNuDIcpExHH8NBM3N3hxerN5e', '2026-04-02 07:57:02.823904+00', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "email", "providers": ["email"]}', '{}', false, '2026-04-02 07:57:02.823904+00', '2026-04-02 07:57:02.823904+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '0a7c8648-f7d2-43d0-abd4-6d8926199831', 'authenticated', 'authenticated', 'userg@gmail.com', '$2a$10$ho/H8RwUj/6IbQviPhBAwefnm5paIoQQbekQkv/3KRX6ns8UkzEB6', '2026-02-01 05:40:21.908986+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-04-09 04:53:40.407999+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2026-02-01 05:40:21.907707+00', '2026-04-09 04:53:40.408973+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '2efccfdb-cdd0-4418-aecb-0351727564ed', 'authenticated', 'authenticated', 'caisse@gmail.com', '$2a$10$kg1z8wHlbdiCsMStd4qI9.qVreeqod9SS7lcPHF5kzjDNtK6BTiw.', '2026-02-06 17:49:40.092241+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-04-07 14:08:08.966096+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2026-02-06 17:49:40.087002+00', '2026-04-07 14:08:08.967584+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '960da502-2ea7-485d-945e-2c4613553eb7', 'authenticated', 'authenticated', 'user@gmail.com', '$2a$10$Bqc0fwmkhvevKT/QVb09YuQ1WPxLU0EFoM8.iZEvET9EYh9rQ/StO', '2026-02-01 05:39:57.421148+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-04-09 05:22:38.437878+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2026-02-01 05:39:57.41769+00', '2026-04-09 05:22:38.438592+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('960da502-2ea7-485d-945e-2c4613553eb7', '960da502-2ea7-485d-945e-2c4613553eb7', '{"sub": "960da502-2ea7-485d-945e-2c4613553eb7", "email": "user@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-01 05:39:57.419538+00', '2026-02-01 05:39:57.419579+00', '2026-02-01 05:39:57.419579+00', '8b868512-fe2b-425b-93b4-969cbd62b212');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('0a7c8648-f7d2-43d0-abd4-6d8926199831', '0a7c8648-f7d2-43d0-abd4-6d8926199831', '{"sub": "0a7c8648-f7d2-43d0-abd4-6d8926199831", "email": "userg@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-01 05:40:21.908332+00', '2026-02-01 05:40:21.908355+00', '2026-02-01 05:40:21.908355+00', '37ba41d8-b965-4af7-b892-2f1d46b28a4e');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('1976b828-a5ef-48d2-adc1-707d4e83ede2', '1976b828-a5ef-48d2-adc1-707d4e83ede2', '{"sub": "1976b828-a5ef-48d2-adc1-707d4e83ede2", "email": "admin@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-01 05:41:20.153244+00', '2026-02-01 05:41:20.15327+00', '2026-02-01 05:41:20.15327+00', '1a87b61d-0db0-4e19-98dc-b4940256f5e4');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('2efccfdb-cdd0-4418-aecb-0351727564ed', '2efccfdb-cdd0-4418-aecb-0351727564ed', '{"sub": "2efccfdb-cdd0-4418-aecb-0351727564ed", "email": "caisse@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-06 17:49:40.090401+00', '2026-02-06 17:49:40.090461+00', '2026-02-06 17:49:40.090461+00', '1810ccc8-702a-493b-96d0-fa670b1222c0');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('95999340-b964-429b-9750-2ec86d656fb8', '95999340-b964-429b-9750-2ec86d656fb8', '{"sub": "95999340-b964-429b-9750-2ec86d656fb8", "email": "labo@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-04-02 08:37:53.110959+00', '2026-04-02 08:37:53.111014+00', '2026-04-02 08:37:53.111014+00', 'a92ef216-c9cf-49bd-b83b-6f9b8b1f2795');


--
-- PostgreSQL database dump complete
--

