{{ config(materialized='view') }}

select
    source.*,
    {{ julian_datetime('source.cuupdd', 'source.cuupdt') }} as last_update_datetime,
    {{ julian_date('source.cusrd1') }} as user_defined_date,
    {{ julian_date('source.curkdt') }} as rank_change_date,
    {{ julian_date('source.culcnt') }} as last_contact_date,
    {{ julian_date('source.culord') }} as last_order_booked_date,
    {{ julian_date('source.cucdat') }} as contract_date,
    {{ julian_date('source.cumdat') }} as contract_mailed_date,
    {{ julian_date('source.cucsdt') }} as contract_signed_date,
    {{ julian_date('source.cumldt') }} as last_mailing_date
from {{ source('iesfilec', 'custmast') }} as source
