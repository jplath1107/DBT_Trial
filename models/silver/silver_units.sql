{{ config(materialized='view') }}

{% set units_source = source('iesfilec', 'units') %}
{% set julian_conversions = {
    'unterm': [julian_date('source.unterm') ~ ' as termination_date'],
    'unhirw': [julian_date('source.unhirw') ~ ' as hire_date'],
    'unetat': [julian_datetime('source.unecdt', 'source.unetat') ~ ' as estimated_arrival_datetime'],
    'uncntt': [julian_datetime('source.uncntd', 'source.uncntt') ~ ' as contact_datetime'],
    'unlprd': [julian_date('source.unlprd') ~ ' as last_purchase_date'],
    'un1prd': [julian_date('source.un1prd') ~ ' as first_purchase_date'],
    'unpprd': [julian_date('source.unpprd') ~ ' as previous_purchase_date'],
    'unpta': [julian_datetime('source.unpda', 'source.unpta') ~ ' as projected_available_datetime'],
    'unpcdt': [julian_date('source.unpcdt') ~ ' as projected_availability_change_date'],
    'unhdte': [julian_date('source.unhdte') ~ ' as temporary_hold_date'],
    'unusr1': [julian_date('source.unusr1') ~ ' as user_defined_date']
} %}

select
    {{ select_columns_from_comments(units_source, 'source', ['termination_date', 'hire_date', 'estimated_arrival_datetime', 'contact_datetime', 'last_purchase_date', 'first_purchase_date', 'previous_purchase_date', 'projected_available_datetime', 'projected_availability_change_date', 'temporary_hold_date', 'user_defined_date', 'write_timestamp', 'update_timestamp'], julian_conversions) }},
    try_to_timestamp_ntz(nullif(trim(source.u1_wtims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as write_timestamp,
    try_to_timestamp_ntz(nullif(trim(source.u1_utims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as update_timestamp
from {{ units_source }} as source
