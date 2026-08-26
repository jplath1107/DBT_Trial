{{ config(materialized='view') }}

{% set billing_source = source('iesfilec', 'billing') %}

select
    {{ select_columns_from_comments(billing_source, 'source', ['write_timestamp', 'update_timestamp']) }},
    try_to_timestamp_ntz(nullif(trim(source.bi_wtims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as write_timestamp,
    try_to_timestamp_ntz(nullif(trim(source.bi_utims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as update_timestamp
from {{ billing_source }} as source
