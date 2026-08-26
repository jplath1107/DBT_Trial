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
