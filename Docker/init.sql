-- =====================================================================
--  interop_masterdata_fhir_colombia / docker/init.sql
--  Inicialización completa del esquema HCD con tablas clínicas y datos de ejemplo
-- =====================================================================

-- ================================
-- [0] CONFIGURACIÓN INICIAL
-- ================================
CREATE SCHEMA IF NOT EXISTS hcd;
SET search_path TO hcd, public;

-- Extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================
-- [1] CATÁLOGOS DE REFERENCIA
-- ================================

-- 1.1 ISO-3166
DROP TABLE IF EXISTS hcd.catalogo_iso3166 CASCADE;
CREATE TABLE hcd.catalogo_iso3166 (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
INSERT INTO hcd.catalogo_iso3166 (code, name) VALUES
('CO','Colombia'),('US','Estados Unidos'),('BR','Brasil'),('AR','Argentina'),
('MX','México'),('CL','Chile'),('PE','Perú'),('ES','España'),('FR','Francia'),('DE','Alemania');

-- 1.2 UCUM
DROP TABLE IF EXISTS hcd.catalogo_ucum CASCADE;
CREATE TABLE hcd.catalogo_ucum (
    code VARCHAR(20) PRIMARY KEY,
    display VARCHAR(100) NOT NULL
);
INSERT INTO hcd.catalogo_ucum (code, display) VALUES
('kg','kilogram'),('g','gram'),('mg','milligram'),('L','liter'),('mL','milliliter'),
('cm','centimeter'),('m','meter'),('mmHg','millimeter of mercury'),('°C','degree Celsius');

-- 1.3 Códigos SNOMED-CT básicos
DROP TABLE IF EXISTS hcd.catalogo_snomed CASCADE;
CREATE TABLE hcd.catalogo_snomed (
    code VARCHAR(20) PRIMARY KEY,
    display VARCHAR(200) NOT NULL,
    system VARCHAR(100) DEFAULT 'http://snomed.info/sct'
);
INSERT INTO hcd.catalogo_snomed (code, display) VALUES
('26643006','Oral route'),('47625008','Intravenous route'),('78421000','Intramuscular route'),
('34206005','Subcutaneous route'),('16857009','Vaginal route'),('12130007','Nasal route'),
('54471007','Buccal route'),('37161004','Rectal route'),('18679011','Inhalation route');

-- ================================
-- [2] TABLAS FHIR SIMULADAS
-- ================================

-- 2.1 Tabla Patient FHIR
DROP TABLE IF EXISTS hcd.patient CASCADE;
CREATE TABLE hcd.patient (
    id VARCHAR(64) PRIMARY KEY,
    resource_type VARCHAR(20) DEFAULT 'Patient',
    identifier JSONB,
    active BOOLEAN DEFAULT true,
    name JSONB,
    gender VARCHAR(20),
    birth_date DATE,
    telecom JSONB,
    address JSONB,
    meta JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.2 Tabla Practitioner FHIR
DROP TABLE IF EXISTS hcd.practitioner CASCADE;
CREATE TABLE hcd.practitioner (
    id VARCHAR(64) PRIMARY KEY,
    resource_type VARCHAR(20) DEFAULT 'Practitioner',
    identifier JSONB,
    active BOOLEAN DEFAULT true,
    name JSONB,
    telecom JSONB,
    address JSONB,
    gender VARCHAR(20),
    birth_date DATE,
    qualification JSONB,
    meta JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.3 Tabla Organization FHIR  
DROP TABLE IF EXISTS hcd.organization CASCADE;
CREATE TABLE hcd.organization (
    id VARCHAR(64) PRIMARY KEY,
    resource_type VARCHAR(20) DEFAULT 'Organization',
    identifier JSONB,
    active BOOLEAN DEFAULT true,
    name VARCHAR(200),
    alias JSONB,
    telecom JSONB,
    address JSONB,
    meta JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.4 Tabla Condition FHIR
DROP TABLE IF EXISTS hcd.condition CASCADE;
CREATE TABLE hcd.condition (
    id VARCHAR(64) PRIMARY KEY,
    resource_type VARCHAR(20) DEFAULT 'Condition',
    identifier JSONB,
    clinical_status JSONB,
    verification_status JSONB,
    category JSONB,
    severity JSONB,
    code JSONB,
    subject JSONB, -- referencia al paciente
    encounter JSONB, -- referencia al encounter
    onset_date_time TIMESTAMP,
    recorded_date DATE,
    recorder JSONB, -- referencia al practitioner
    asserter JSONB, -- referencia al practitioner
    meta JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.5 Tabla Encounter FHIR
DROP TABLE IF EXISTS hcd.encounter CASCADE;
CREATE TABLE hcd.encounter (
    id VARCHAR(64) PRIMARY KEY,
    resource_type VARCHAR(20) DEFAULT 'Encounter',
    identifier JSONB,
    status VARCHAR(20),
    class JSONB,
    type JSONB,
    service_type JSONB,
    priority JSONB,
    subject JSONB, -- referencia al paciente
    participant JSONB, -- array de participantes
    period JSONB, -- período del encounter
    reason_code JSONB,
    diagnosis JSONB,
    location JSONB,
    service_provider JSONB, -- referencia a organization
    meta JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.6 Tabla MedicationAdministration FHIR
DROP TABLE IF EXISTS hcd.medication_administration CASCADE;
CREATE TABLE hcd.medication_administration (
    id VARCHAR(64) PRIMARY KEY,
    resource_type VARCHAR(20) DEFAULT 'MedicationAdministration',
    identifier JSONB,
    status VARCHAR(20),
    medication_codeable_concept JSONB,
    subject JSONB, -- referencia al paciente
    context JSONB, -- referencia al encounter
    effective_date_time TIMESTAMP,
    performer JSONB, -- array de performers
    reason_code JSONB,
    request JSONB, -- referencia a MedicationRequest
    dosage JSONB,
    meta JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- [3] DATOS DE EJEMPLO
-- ================================

-- 3.1 Pacientes de ejemplo
INSERT INTO hcd.patient (id, identifier, name, gender, birth_date, meta) VALUES
('patient-001', 
 '[{"system": "http://www.acme.com/identifiers/mrn", "value": "1001001"}]',
 '[{"family": "García", "given": ["María", "Isabel"]}]',
 'female',
 '1985-03-15',
 '{"lastUpdated": "2023-10-15T10:00:00Z"}'
),
('patient-002',
 '[{"system": "http://www.acme.com/identifiers/mrn", "value": "1002002"}]', 
 '[{"family": "Rodríguez", "given": ["Carlos", "Andrés"]}]',
 'male',
 '1978-07-22',
 '{"lastUpdated": "2023-10-15T10:05:00Z"}'
);

-- 3.2 Profesionales de ejemplo
INSERT INTO hcd.practitioner (id, identifier, name, gender, qualification, meta) VALUES
('practitioner-001',
 '[{"system": "http://www.minsalud.gov.co/reps", "value": "REP001234"}]',
 '[{"family": "Martínez", "given": ["Ana", "Lucía"]}]',
 'female',
 '[{"code": {"text": "Médico General"}}]',
 '{"lastUpdated": "2023-10-15T09:00:00Z"}'
),
('practitioner-002',
 '[{"system": "http://www.minsalud.gov.co/reps", "value": "REP005678"}]',
 '[{"family": "López", "given": ["Juan", "Carlos"]}]', 
 'male',
 '[{"code": {"text": "Enfermero"}}]',
 '{"lastUpdated": "2023-10-15T09:05:00Z"}'
);

-- 3.3 Organizaciones de ejemplo
INSERT INTO hcd.organization (id, identifier, name, meta) VALUES
('organization-001',
 '[{"system": "http://www.minsalud.gov.co/habilitacion", "value": "ORG001"}]',
 'Hospital San Juan de Dios',
 '{"lastUpdated": "2023-10-15T08:00:00Z"}'
),
('organization-002',
 '[{"system": "http://www.minsalud.gov.co/habilitacion", "value": "ORG002"}]',
 'Clínica Santa María',
 '{"lastUpdated": "2023-10-15T08:05:00Z"}'
);

-- 3.4 Condiciones de ejemplo
INSERT INTO hcd.condition (id, code, subject, recorded_date, meta) VALUES
('condition-001',
 '{"coding": [{"system": "http://hl7.org/fhir/sid/icd-10", "code": "I10", "display": "Essential hypertension"}]}',
 '{"reference": "Patient/patient-001"}',
 '2023-10-15',
 '{"lastUpdated": "2023-10-15T11:00:00Z"}'
),
('condition-002',
 '{"coding": [{"system": "http://hl7.org/fhir/sid/icd-10", "code": "E11", "display": "Type 2 diabetes mellitus"}]}',
 '{"reference": "Patient/patient-002"}',
 '2023-10-15',
 '{"lastUpdated": "2023-10-15T11:05:00Z"}'
);

-- 3.5 Encuentros de ejemplo
INSERT INTO hcd.encounter (id, status, class, subject, period, meta) VALUES
('encounter-001',
 'finished',
 '{"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"}',
 '{"reference": "Patient/patient-001"}',
 '{"start": "2023-10-15T09:00:00Z", "end": "2023-10-15T10:00:00Z"}',
 '{"lastUpdated": "2023-10-15T10:00:00Z"}'
),
('encounter-002',
 'finished', 
 '{"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"}',
 '{"reference": "Patient/patient-002"}',
 '{"start": "2023-10-15T10:30:00Z", "end": "2023-10-15T11:30:00Z"}',
 '{"lastUpdated": "2023-10-15T11:30:00Z"}'
);

-- 3.6 Administración de medicamentos de ejemplo
INSERT INTO hcd.medication_administration (id, status, medication_codeable_concept, subject, effective_date_time, dosage, meta) VALUES
('medication-admin-001',
 'completed',
 '{"coding": [{"system": "http://www.nlm.nih.gov/research/umls/rxnorm", "code": "197361", "display": "Amlodipine 5 MG Oral Tablet"}]}',
 '{"reference": "Patient/patient-001"}',
 '2023-10-15T09:30:00Z',
 '{"route": {"coding": [{"system": "http://snomed.info/sct", "code": "26643006", "display": "Oral route"}]}}',
 '{"lastUpdated": "2023-10-15T09:30:00Z"}'
);

-- ================================
-- [4] ÍNDICES Y OPTIMIZACIONES
-- ================================

-- Índices para búsquedas comunes
CREATE INDEX idx_patient_identifier ON hcd.patient USING GIN (identifier);
CREATE INDEX idx_practitioner_identifier ON hcd.practitioner USING GIN (identifier);
CREATE INDEX idx_condition_subject ON hcd.condition USING GIN (subject);
CREATE INDEX idx_encounter_subject ON hcd.encounter USING GIN (subject);
CREATE INDEX idx_medication_admin_subject ON hcd.medication_administration USING GIN (subject);

-- Índices por fecha
CREATE INDEX idx_patient_birth_date ON hcd.patient (birth_date);
CREATE INDEX idx_condition_recorded_date ON hcd.condition (recorded_date);
CREATE INDEX idx_medication_admin_effective_date ON hcd.medication_administration (effective_date_time);

-- ================================
-- [5] VISTAS ÚTILES
-- ================================

-- Vista consolidada de pacientes
CREATE OR REPLACE VIEW hcd.v_patients_summary AS
SELECT 
    p.id,
    p.identifier->0->>'value' as identifier_value,
    p.name->0->>'family' as family_name,
    p.name->0->'given'->>0 as given_name,
    p.gender,
    p.birth_date,
    p.active,
    COUNT(c.id) as condition_count,
    COUNT(e.id) as encounter_count
FROM hcd.patient p
LEFT JOIN hcd.condition c ON c.subject->>'reference' = 'Patient/' || p.id
LEFT JOIN hcd.encounter e ON e.subject->>'reference' = 'Patient/' || p.id
GROUP BY p.id, p.identifier, p.name, p.gender, p.birth_date, p.active;

-- Vista consolidada de profesionales
CREATE OR REPLACE VIEW hcd.v_practitioners_summary AS
SELECT 
    pr.id,
    pr.identifier->0->>'value' as identifier_value,
    pr.name->0->>'family' as family_name,
    pr.name->0->'given'->>0 as given_name,
    pr.gender,
    pr.qualification->0->'code'->>'text' as qualification_text,
    pr.active
FROM hcd.practitioner pr;

-- ================================
-- [6] FUNCIONES ÚTILES
-- ================================

-- Función para extraer códigos FHIR
CREATE OR REPLACE FUNCTION hcd.extract_fhir_code(coding_json JSONB, system_filter TEXT DEFAULT NULL)
RETURNS TEXT AS $$
BEGIN
    IF coding_json IS NULL OR jsonb_array_length(coding_json) = 0 THEN
        RETURN NULL;
    END IF;
    
    IF system_filter IS NOT NULL THEN
        RETURN (
            SELECT (coding->>'code')::TEXT
            FROM jsonb_array_elements(coding_json) AS coding
            WHERE coding->>'system' = system_filter
            LIMIT 1
        );
    ELSE
        RETURN coding_json->0->>'code';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función para extraer display de códigos FHIR  
CREATE OR REPLACE FUNCTION hcd.extract_fhir_display(coding_json JSONB, system_filter TEXT DEFAULT NULL)
RETURNS TEXT AS $$
BEGIN
    IF coding_json IS NULL OR jsonb_array_length(coding_json) = 0 THEN
        RETURN NULL;
    END IF;
    
    IF system_filter IS NOT NULL THEN
        RETURN (
            SELECT (coding->>'display')::TEXT
            FROM jsonb_array_elements(coding_json) AS coding
            WHERE coding->>'system' = system_filter
            LIMIT 1
        );
    ELSE
        RETURN coding_json->0->>'display';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ================================
-- [7] COMENTARIOS FINALES
-- ================================

COMMENT ON SCHEMA hcd IS 'Esquema para datos de salud y recursos FHIR - Interoperabilidad Colombia';
COMMENT ON TABLE hcd.patient IS 'Recursos Patient FHIR - Información de pacientes';
COMMENT ON TABLE hcd.practitioner IS 'Recursos Practitioner FHIR - Información de profesionales de salud';
COMMENT ON TABLE hcd.organization IS 'Recursos Organization FHIR - Información de organizaciones de salud';
COMMENT ON TABLE hcd.condition IS 'Recursos Condition FHIR - Condiciones y diagnósticos';
COMMENT ON TABLE hcd.encounter IS 'Recursos Encounter FHIR - Encuentros clínicos';
COMMENT ON TABLE hcd.medication_administration IS 'Recursos MedicationAdministration FHIR - Administración de medicamentos';

-- Mensaje de finalización
SELECT 'Base de datos FHIR Colombia inicializada correctamente' AS status;