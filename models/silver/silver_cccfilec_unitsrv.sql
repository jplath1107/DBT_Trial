{{ config(materialized='view') }}

{% set unit_service_source = source('cccfilec', 'unitsrv') %}

select
    {{ select_columns_from_comments(unit_service_source, 'source', ['service_date', 'trip_movement_datetime', 'order_dispatch_date', 'order_empty_date', 'estimated_arrival_datetime', 'projected_available_datetime', 'contact_datetime']) }},
    {{ julian_date('source.srvdat') }} as service_date,
    {{ julian_datetime('source.srvst2', 'source.srvstm') }} as trip_movement_datetime,
    {{ julian_date('source.srddat') }} as order_dispatch_date,
    {{ julian_date('source.sredat') }} as order_empty_date,
    {{ julian_datetime('source.sretad', 'source.sretat') }} as estimated_arrival_datetime,
    {{ julian_datetime('source.srpda', 'source.srpta') }} as projected_available_datetime,
    {{ julian_datetime('source.srcntd', 'source.srcntt') }} as contact_datetime
from {{ unit_service_source }} as source
