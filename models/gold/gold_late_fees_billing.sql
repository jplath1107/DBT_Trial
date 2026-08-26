{{ config(materialized='table') }}

with billing_detail as (
    select
        biodr,
        biamt,
        case
            when bicomm = 'LOTO' then 1
            when bicomm = 'LOTC' then 90
        end as stop
    from {{ source('iesfilec', 'billing') }}
    where bicomm like 'LOT%'
),

late_fee_advances as (
    select
        trim(sa01a) as trip,
        sa02a as stop,
        sa07a as fee,
        rtrim(sa08a) as advance_reason
    from {{ source('cccfilec', 'op0516aa') }}
    where rtrim(sa08a) = 'LATE FEE'
),

order_dates as (
    select
        order_number,
        shipper,
        customer,
        origin_city,
        origin_state,
        destination_city,
        destination_state,
        company_number,
        commodity_code,
        loaded_call_date,
        empty_call_date
    from {{ ref('silver_order') }}
),

stop_details as (
    select
        order_number,
        stop_number,
        customer_code,
        early_appointment_datetime,
        appointment_datetime
    from {{ ref('silver_stopoff') }}
)

select
    advances.trip,
    advances.stop,
    advances.fee,
    advances.advance_reason,
    orders.shipper as shipper_code,
    orders.customer as consignee,
    load_date.date as load_date,
    orders.origin_state,
    orders.destination_state as dest_state,
    orders.company_number as company,
    empty_date.date as empty_date,
    orders.commodity_code as commodity,
    billing.biamt as fee_charged_to_customer_old,
    destination_city.ciname as dest_city,
    origin_city.ciname as origin_city,
    stops.customer_code as stop_code,
    stops.early_appointment_datetime,
    stops.appointment_datetime as late_appt_datetime,
    stop_customer.cuname as stop_name
from late_fee_advances as advances
left join order_dates as orders
    on advances.trip = trim(orders.order_number)
left join {{ source('dbo', 'dim_date') }} as load_date
    on orders.loaded_call_date = load_date.juldate
left join {{ source('dbo', 'dim_date') }} as empty_date
    on orders.empty_call_date = empty_date.juldate
left join billing_detail as billing
    on advances.trip = trim(billing.biodr)
   and advances.stop = billing.stop
left join {{ source('iesfilec', 'cities') }} as destination_city
    on orders.destination_state = destination_city.cist
   and trim(orders.destination_city) = trim(destination_city.cicty)
left join {{ source('iesfilec', 'cities') }} as origin_city
    on orders.origin_state = origin_city.cist
   and trim(orders.origin_city) = trim(origin_city.cicty)
left join stop_details as stops
    on advances.trip = trim(stops.order_number)
   and advances.stop = stops.stop_number
left join {{ source('iesfilec', 'custmast') }} as stop_customer
    on stops.customer_code = stop_customer.cucode
