{{ config(materialized='view') }}

{% set bill_pay_source = source('cccfilec', 'op0710bp') %}

select
    {{ select_columns_from_comments(bill_pay_source, 'source', ['event_date_gregorian', 'date_from_gregorian', 'date_to_gregorian']) }},
    {{ julian_date('source.event_date') }} as event_date_gregorian,
    {{ julian_date('source.date_from') }} as date_from_gregorian,
    {{ julian_date('source.date_to') }} as date_to_gregorian
from {{ bill_pay_source }} as source
