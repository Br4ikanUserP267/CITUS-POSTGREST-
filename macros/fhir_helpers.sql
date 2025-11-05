{% macro extract_fhir_code(coding_column, system_filter=none, index=0) %}{% macro extract_fhir_code(coding_column, system_filter=none, index=0) %}

    case     case 

        when {{ coding_column }} is not null         when {{ coding_column }} is not null 

        and json_array_length({{ coding_column }}) > {{ index }}        and json_array_length({{ coding_column }}) > {{ index }}

        {% if system_filter %}        {% if system_filter %}

        and {{ coding_column }}->{{ index }}->>'system' = '{{ system_filter }}'        and {{ coding_column }}->{{ index }}->>'system' = '{{ system_filter }}'

        {% endif %}        {% endif %}

        then {{ coding_column }}->{{ index }}->>'code'        then {{ coding_column }}->{{ index }}->>'code'

    end    end

{% endmacro %}{% endmacro %}



{% macro extract_fhir_display(coding_column, system_filter=none, index=0) %}{% macro extract_fhir_display(coding_column, system_filter=none, index=0) %}

    case     case 

        when {{ coding_column }} is not null         when {{ coding_column }} is not null 

        and json_array_length({{ coding_column }}) > {{ index }}        and json_array_length({{ coding_column }}) > {{ index }}

        {% if system_filter %}        {% if system_filter %}

        and {{ coding_column }}->{{ index }}->>'system' = '{{ system_filter }}'        and {{ coding_column }}->{{ index }}->>'system' = '{{ system_filter }}'

        {% endif %}        {% endif %}

        then {{ coding_column }}->{{ index }}->>'display'        then {{ coding_column }}->{{ index }}->>'display'

    end    end

{% endmacro %}{% endmacro %}



{% macro extract_patient_id_from_reference(reference_column) %}{% macro extract_patient_id_from_reference(reference_column) %}

    case     case 

        when {{ reference_column }}->>'reference' like 'Patient/%'        when {{ reference_column }}->>'reference' like 'Patient/%'

        then split_part({{ reference_column }}->>'reference', '/', 2)        then split_part({{ reference_column }}->>'reference', '/', 2)

    end    end

{% endmacro %}{% endmacro %}