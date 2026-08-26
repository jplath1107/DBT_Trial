{{ config(materialized='view') }}

{% set driver_performance_source = source('peoplenet', 'performxbydriverdata') %}

select
    {{ select_columns_from_comments(driver_performance_source, 'source') }}
from {{ driver_performance_source }} as source
