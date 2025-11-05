{{ config(materialized='view') }}{{ config(materialized='view') }}



-- Modelo de staging para pacientes FHIR-- Modelo de staging para pacientes FHIR

-- Extrae y limpia los datos básicos de pacientes-- Extrae y limpia los datos básicos de pacientes



selectselect

    id as patient_id,    id as patient_id,

    -- Extraer identificador principal    -- Extraer identificador principal

    case     case 

        when identifier is not null and json_array_length(identifier) > 0        when identifier is not null and json_array_length(identifier) > 0

        then identifier->0->>'value'        then identifier->0->>'value'

    end as identifier_value,    end as identifier_value,

        

    case     case 

        when identifier is not null and json_array_length(identifier) > 0        when identifier is not null and json_array_length(identifier) > 0

        then identifier->0->>'system'        then identifier->0->>'system'

    end as identifier_system,    end as identifier_system,

        

    -- Extraer nombre    -- Extraer nombre

    case     case 

        when name is not null and json_array_length(name) > 0        when name is not null and json_array_length(name) > 0

        then name->0->>'family'        then name->0->>'family'

    end as name_family,    end as name_family,

        

    case     case 

        when name is not null and json_array_length(name) > 0        when name is not null and json_array_length(name) > 0

        then name->0->'given'->>0        then name->0->'given'->>0

    end as name_given,    end as name_given,

        

    gender,    gender,

    birth_date::date as birth_date,    birth_date::date as birth_date,

    active::boolean as active,    active::boolean as active,

        

    -- Metadatos    -- Metadatos

    meta->>'lastUpdated' as last_updated,    meta->>'lastUpdated' as last_updated,

    resource_type,    resource_type,

        

    -- Timestamp de procesamiento    -- Timestamp de procesamiento

    current_timestamp as processed_at    current_timestamp as processed_at



from {{ source('fhir_raw', 'patient') }}from {{ source('fhir_raw', 'patient') }}

where id is not nullwhere id is not null