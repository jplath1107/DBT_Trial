{{ config(materialized='view') }}

select
    source.*,
    try_to_timestamp_ntz(
        nullif(trim(source.bi_wtims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as write_timestamp,
    try_to_timestamp_ntz(
        nullif(trim(source.bi_utims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as update_timestamp
from {{ source('iesfilec', 'billing') }} as source
