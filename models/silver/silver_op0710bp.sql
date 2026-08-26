{{ config(materialized='view', alias='bill_pay') }}

select
    source.*,
    {{ julian_date('source.event_date') }} as event_date_gregorian,
    {{ julian_date('source.date_from') }} as date_from_gregorian,
    {{ julian_date('source.date_to') }} as date_to_gregorian
from {{ source('cccfilec', 'op0710bp') }} as source
