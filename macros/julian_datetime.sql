{% macro julian_date(julian_date) %}
    case
        when nullif({{ julian_date }}::varchar, '0') is not null then
            try_to_date(
                to_char(
                    dateadd(
                        day,
                        right({{ julian_date }}::varchar, 3)::integer - 1,
                        date_from_parts(left({{ julian_date }}::varchar, 4)::integer, 1, 1)
                    ),
                    'YYYY-MM-DD'
                ),
                'YYYY-MM-DD'
            )
    end
{% endmacro %}

{% macro julian_datetime(julian_date, julian_time) %}
    case
        when nullif({{ julian_date }}::varchar, '0') is not null
         and nullif({{ julian_time }}::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(
                    dateadd(
                        day,
                        right({{ julian_date }}::varchar, 3)::integer - 1,
                        date_from_parts(left({{ julian_date }}::varchar, 4)::integer, 1, 1)
                    ),
                    'YYYY-MM-DD'
                ) || ' ' || lpad({{ julian_time }}::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end
{% endmacro %}



{% macro julian_datetime_seconds(julian_date, julian_time) %}
    case
        when nullif({{ julian_date }}::varchar, '0') is not null
         and nullif({{ julian_time }}::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(
                    dateadd(
                        day,
                        right({{ julian_date }}::varchar, 3)::integer - 1,
                        date_from_parts(left({{ julian_date }}::varchar, 4)::integer, 1, 1)
                    ),
                    'YYYY-MM-DD'
                ) || ' ' || lpad({{ julian_time }}::varchar, 6, '0'),
                'YYYY-MM-DD HH24MISS'
            )
    end
{% endmacro %}



{% macro select_columns_from_comments(source_relation, relation_alias, reserved_aliases=[], derived_columns_after={}) %}
    {% if execute %}
        {% set comment_column_query %}
            with normalized_columns as (
                select
                    column_name,
                    ordinal_position,
                    nullif(
                        regexp_replace(
                            regexp_replace(lower(trim(comment)), '[^a-z0-9]+', '_'),
                            '(^_+|_+$)',
                            ''
                        ),
                        ''
                    ) as normalized_comment
                from {{ source_relation.database }}.information_schema.columns
                where table_schema = upper('{{ source_relation.schema }}')
                  and table_name = upper('{{ source_relation.identifier }}')
            ),

            candidate_columns as (
                select
                    column_name,
                    ordinal_position,
                    case
                        when normalized_comment is null then column_name
                        when count(*) over (partition by normalized_comment) > 1 then column_name
                        else normalized_comment
                    end as alias_name
                from normalized_columns
            ),

            unique_columns as (
                select
                    column_name,
                    ordinal_position,
                    alias_name,
                    count(*) over (partition by alias_name) as alias_count
                from candidate_columns
            )

            select
                column_name,
                case
                    when alias_count > 1 then column_name
                    else alias_name
                end as alias_name
            from unique_columns
            order by ordinal_position
        {% endset %}

        {% set columns = run_query(comment_column_query) %}
        {% set projections = [] %}

        {% for column in columns %}
            {% set column_name = column[0] %}
            {% set alias_name = column[1] %}
            {% set output_alias = alias_name %}
            {% if output_alias | lower in reserved_aliases %}
                {% set output_alias = output_alias ~ '_raw' %}
            {% endif %}

            {% do projections.append(relation_alias ~ '.' ~ adapter.quote(column_name) ~ ' as ' ~ adapter.quote(output_alias | upper)) %}
            {% for derived_column in derived_columns_after.get(column_name | lower, []) %}
                {% do projections.append(derived_column) %}
            {% endfor %}
        {% endfor %}

        {{ projections | join(',\n    ') }}
    {% else %}
        {{ relation_alias }}.*
    {% endif %}
{% endmacro %}

