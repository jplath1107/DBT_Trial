{{ config(materialized='view') }}

select
    source.*,
    {{ julian_date('source.unterm') }} as termination_date,
    {{ julian_date('source.unhirw') }} as hire_date,
    {{ julian_datetime('source.unecdt', 'source.unetat') }} as estimated_arrival_datetime,
    {{ julian_datetime('source.uncntd', 'source.uncntt') }} as contact_datetime,
    {{ julian_date('source.unlprd') }} as last_purchase_date,
    {{ julian_date('source.un1prd') }} as first_purchase_date,
    {{ julian_date('source.unpprd') }} as previous_purchase_date,
    {{ julian_datetime('source.unpda', 'source.unpta') }} as projected_available_datetime,
    {{ julian_date('source.unpcdt') }} as projected_availability_change_date,
    {{ julian_date('source.unhdte') }} as temporary_hold_date,
    {{ julian_date('source.unusr1') }} as user_defined_date,
    try_to_timestamp_ntz(
        nullif(trim(source.u1_wtims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as write_timestamp,
    try_to_timestamp_ntz(
        nullif(trim(source.u1_utims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as update_timestamp
from {{ source('iesfilec', 'units') }} as source
