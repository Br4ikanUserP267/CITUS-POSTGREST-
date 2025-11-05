{{ config(materialized='table') }}{{ config(materialized='table') }}



-- Datos maestros de pacientes consolidados-- Datos maestros de pacientes consolidados

-- Este modelo combina y valida la información de pacientes desde múltiples fuentes

with patient_base as (

    select * from {{ ref('stg_fhir_patient') }}with patient_base as (

),    select * from {{ ref('stg_fhir_patient') }}

),

patient_enhanced as (

    selectpatient_with_validations as (

        patient_id,    select

        identifier_value,        patient_id,

        identifier_system,        identifier_value,

        name_family,        identifier_system,

        name_given,        name_family,

                name_given,

        -- Nombre completo        

        case         -- Nombre completo concatenado

            when name_given is not null and name_family is not null        case 

            then name_given || ' ' || name_family            when name_given is not null and name_family is not null

            when name_given is not null             then name_given || ' ' || name_family

            then name_given            when name_given is not null 

            when name_family is not null            then name_given

            then name_family            when name_family is not null

        end as full_name,            then name_family

                end as full_name,

        gender,        

        birth_date,        gender,

        active,        birth_date,

        last_updated,        

        processed_at,        -- Calcular edad si la fecha de nacimiento es válida

                case 

        -- Validaciones de calidad            when birth_date is not null and birth_date <= current_date

        case             then extract(year from age(current_date, birth_date))::int

            when identifier_value is null or identifier_value = ''         end as age_years,

            then false         

            else true         active,

        end as has_valid_identifier,        last_updated,

                processed_at,

        case         

            when name_family is null and name_given is null         -- Flags de calidad de datos

            then false         case 

            else true             when identifier_value is null or identifier_value = '' 

        end as has_name_info,            then false 

                    else true 

        case         end as has_valid_identifier,

            when birth_date is null         

            then false         case 

            else true             when name_family is null and name_given is null 

        end as has_birth_date            then false 

            else true 

    from patient_base        end as has_name_info,

)        

        case 

select            when birth_date is null or birth_date > current_date 

    *,            then false 

    -- Score de calidad            else true 

    (        end as has_valid_birthdate

        case when has_valid_identifier then 0.4 else 0 end +

        case when has_name_info then 0.4 else 0 end +    from patient_base

        case when has_birth_date then 0.2 else 0 end)

    ) as data_quality_score

select

from patient_enhanced    *,
    -- Score de calidad general (0-1)
    (
        case when has_valid_identifier then 0.4 else 0 end +
        case when has_name_info then 0.3 else 0 end +
        case when has_valid_birthdate then 0.3 else 0 end
    ) as data_quality_score

from patient_with_validations