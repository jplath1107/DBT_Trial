{{ config(materialized='view') }}

{% set comment_source = source('iesfilec', 'comment') %}
{% set julian_conversions = {
    'ocdate': [julian_date('source.ocdate') ~ ' as comment_date'],
    'occrtt': [julian_datetime_seconds('source.occrtd', 'source.occrtt') ~ ' as created_datetime'],
    'occhgt': [julian_datetime_seconds('source.occhgd', 'source.occhgt') ~ ' as changed_datetime']
} %}

select
    {{ select_columns_from_comments(
        comment_source,
        'source',
        ['comment_date', 'created_datetime', 'changed_datetime', 'write_timestamp', 'update_timestamp'],
        julian_conversions
    ) }},
    try_to_timestamp_ntz(
        nullif(trim(source.oc_wtims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as write_timestamp,
    try_to_timestamp_ntz(
        nullif(trim(source.oc_utims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as update_timestamp
from {{ comment_source }} as source
