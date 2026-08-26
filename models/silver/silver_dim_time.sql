{{ config(materialized='view') }}

{% set time_dimension_source = source('dbo', 'dim_time') %}

select
    {{ select_columns_from_comments(time_dimension_source, 'source') }}
from {{ time_dimension_source }} as source
