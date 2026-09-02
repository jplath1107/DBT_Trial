{{ config(materialized='view') }}

{% set customer_master_source = source('iesfilec', 'custmast') %}
{% set julian_conversions = {
    'cuupdt': [julian_datetime('source.cuupdd', 'source.cuupdt') ~ ' as last_update_datetime'],
    'cusrd1': [julian_date('source.cusrd1') ~ ' as user_defined_date'],
    'curkdt': [julian_date('source.curkdt') ~ ' as rank_change_date'],
    'culcnt': [julian_date('source.culcnt') ~ ' as last_contact_date'],
    'culord': [julian_date('source.culord') ~ ' as last_order_booked_date'],
    'cucdat': [julian_date('source.cucdat') ~ ' as contract_date'],
    'cumdat': [julian_date('source.cumdat') ~ ' as contract_mailed_date'],
    'cucsdt': [julian_date('source.cucsdt') ~ ' as contract_signed_date'],
    'cumldt': [julian_date('source.cumldt') ~ ' as last_mailing_date']
} %}

select
    {{ select_columns_from_comments(customer_master_source, 'source', ['last_update_datetime', 'user_defined_date', 'rank_change_date', 'last_contact_date', 'last_order_booked_date', 'contract_date', 'contract_mailed_date', 'contract_signed_date', 'last_mailing_date', 'write_timestamp', 'update_timestamp'], julian_conversions) }},
    try_to_timestamp_ntz(nullif(trim(source.cu_wtims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as write_timestamp,
    try_to_timestamp_ntz(nullif(trim(source.cu_utims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as update_timestamp
from {{ customer_master_source }} as source
