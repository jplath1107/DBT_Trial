{{ config(materialized='view', alias='historical_unit_service') }}

select
    source.*,
    {{ julian_date('source.srvdat') }} as service_date,
    {{ julian_datetime('source.srvst2', 'source.srvstm') }} as trip_movement_datetime,
    {{ julian_date('source.srddat') }} as order_dispatch_date,
    {{ julian_date('source.sredat') }} as order_empty_date,
    {{ julian_datetime('source.sretad', 'source.sretat') }} as estimated_arrival_datetime,
    {{ julian_datetime('source.srpda', 'source.srpta') }} as projected_available_datetime,
    {{ julian_datetime('source.srcntd', 'source.srcntt') }} as contact_datetime
from {{ source('cccfilet', 'unitsrv') }} as source
