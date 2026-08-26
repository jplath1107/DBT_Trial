{{ config(materialized='view') }}

{% set trip_source = source('cccfilec', 'op0568trp') %}

select
    {{ select_columns_from_comments(trip_source, 'source') }}
from {{ trip_source }} as source
