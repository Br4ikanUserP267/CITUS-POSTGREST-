{{ config(materialized='view') }}{{ config(materialized='view') }}



-- Modelo de staging para condiciones FHIR-- Modelo de staging para condiciones FHIR

-- Extrae y limpia los datos de condiciones médicas-- Extrae y limpia los datos de condiciones médicas



selectselect

    id as condition_id,    id as condition_id,

    subject->>'reference' as patient_reference,    subject->>'reference' as patient_reference,

        

    -- Extraer ID del paciente desde la referencia    -- Extraer ID del paciente desde la referencia

    case     case 

        when subject->>'reference' like 'Patient/%'        when subject->>'reference' like 'Patient/%'

        then split_part(subject->>'reference', '/', 2)        then split_part(subject->>'reference', '/', 2)

    end as patient_id,    end as patient_id,

        

    -- Extraer información del código principal    -- Extraer información del código principal

    case     case 

        when code->'coding' is not null and json_array_length(code->'coding') > 0        when code->'coding' is not null and json_array_length(code->'coding') > 0

        then code->'coding'->0->>'system'        then code->'coding'->0->>'system'

    end as code_system,    end as code_system,

        

    case     case 

        when code->'coding' is not null and json_array_length(code->'coding') > 0        when code->'coding' is not null and json_array_length(code->'coding') > 0

        then code->'coding'->0->>'code'        then code->'coding'->0->>'code'

    end as code_value,    end as code_value,

        

    case     case 

        when code->'coding' is not null and json_array_length(code->'coding') > 0        when code->'coding' is not null and json_array_length(code->'coding') > 0

        then code->'coding'->0->>'display'        then code->'coding'->0->>'display'

    end as display_text,    end as display_text,

        

    -- Texto libre de la condición    -- Texto libre de la condición

    code->>'text' as condition_text,    code->>'text' as condition_text,

        

    -- Categoría de la condición    -- Categoría de la condición

    case     case 

        when category is not null and json_array_length(category) > 0        when category is not null and json_array_length(category) > 0

        then category->0->'coding'->0->>'display'        then category->0->'coding'->0->>'display'

    end as category_display,    end as category_display,

        

    -- Estado de verificación    -- Estado de verificación

    verification_status->'coding'->0->>'code' as verification_status,    verification_status->'coding'->0->>'code' as verification_status,

        

    -- Severidad    -- Severidad

    case     case 

        when severity is not null        when severity is not null

        then severity->'coding'->0->>'display'        then severity->'coding'->0->>'display'

    end as severity_display,    end as severity_display,

        

    -- Fechas    -- Fechas

    recorded_date::date as recorded_date,    recorded_date::date as recorded_date,

    onset_date_time::timestamp as onset_datetime,    onset_date_time::timestamp as onset_datetime,

        

    -- Metadatos    -- Metadatos

    meta->>'lastUpdated' as last_updated,    meta->>'lastUpdated' as last_updated,

    current_timestamp as processed_at    current_timestamp as processed_at



from {{ source('fhir_raw', 'condition') }}from {{ source('fhir_raw', 'condition') }}

where id is not nullwhere id is not null