{{ config(materialized='view') }}

{% set bill_pay_source = source('cccfilec', 'op0710bp') %}
{% set julian_conversions = {
    'event_date': [julian_date('source.event_date') ~ ' as event_date_gregorian'],
    'date_from': [julian_date('source.date_from') ~ ' as date_from_gregorian'],
    'date_to': [julian_date('source.date_to') ~ ' as date_to_gregorian']
} %}

select
    {{ select_columns_from_comments(bill_pay_source, 'source', ['event_date_gregorian', 'date_from_gregorian', 'date_to_gregorian'], julian_conversions) }}
from {{ bill_pay_source }} as source
