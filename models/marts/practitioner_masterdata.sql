{{ config(materialized='table') }}{{ config(materialized='table') }}



-- Datos maestros de profesionales consolidados-- Datos maestros de profesionales consolidados



with practitioner_base as (with practitioner_base as (

    select * from {{ ref('stg_fhir_practitioner') }}    select * from {{ ref('stg_fhir_practitioner') }}

),),



practitioner_enhanced as (practitioner_enhanced as (

    select    select

        practitioner_id,        practitioner_id,

        identifier_value,        identifier_value,

        identifier_system,        identifier_system,

        name_family,        name_family,

        name_given,        name_given,

                

        -- Nombre completo        -- Nombre completo

        case         case 

            when name_given is not null and name_family is not null            when name_given is not null and name_family is not null

            then name_given || ' ' || name_family            then name_given || ' ' || name_family

            when name_given is not null             when name_given is not null 

            then name_given            then name_given

            when name_family is not null            when name_family is not null

            then name_family            then name_family

        end as full_name,        end as full_name,

                

        active,        active,

        primary_qualification,        primary_qualification,

        last_updated,        last_updated,

        processed_at,        processed_at,

                

        -- Validaciones de calidad        -- Validaciones de calidad

        case         case 

            when identifier_value is null or identifier_value = ''             when identifier_value is null or identifier_value = '' 

            then false             then false 

            else true             else true 

        end as has_valid_identifier,        end as has_valid_identifier,

                

        case         case 

            when name_family is null and name_given is null             when name_family is null and name_given is null 

            then false             then false 

            else true             else true 

        end as has_name_info        end as has_name_info



    from practitioner_base    from practitioner_base

))



selectselect

    *,    *,

    -- Score de calidad    -- Score de calidad

    (    (

        case when has_valid_identifier then 0.5 else 0 end +        case when has_valid_identifier then 0.5 else 0 end +

        case when has_name_info then 0.5 else 0 end        case when has_name_info then 0.5 else 0 end

    ) as data_quality_score    ) as data_quality_score



from practitioner_enhancedfrom practitioner_enhanced