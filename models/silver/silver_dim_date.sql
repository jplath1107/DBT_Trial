{{ config(materialized='view') }}

{% set date_dimension_source = source('dbo', 'dim_date') %}

select
    {{ select_columns_from_comments(date_dimension_source, 'source') }}
from {{ date_dimension_source }} as source
