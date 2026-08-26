{{ config(materialized='view') }}

{% set cities_source = source('iesfilec', 'cities') %}

select
    {{ select_columns_from_comments(cities_source, 'source') }}
from {{ cities_source }} as source
