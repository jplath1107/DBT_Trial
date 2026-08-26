{{ config(materialized='view') }}

{% set user_filter_source = source('cccfilec', 'op0568flt') %}

select
    {{ select_columns_from_comments(user_filter_source, 'source') }}
from {{ user_filter_source }} as source
