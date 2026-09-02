{{ config(materialized='view') }}

{% set advance_source = source('cccfilec', 'op0516aa') %}
{% set julian_conversions = {
    'sa10a': [julian_datetime('source.sa09a', 'source.sa10a') ~ ' as advance_datetime']
} %}

select
    {{ select_columns_from_comments(advance_source, 'source', ['advance_datetime'], julian_conversions) }}
from {{ advance_source }} as source
