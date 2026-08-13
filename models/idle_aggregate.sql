{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='idle_aggregate_id',
        cluster_by=['date']
    )
}}

with performx_by_driver as (
    select
        cid,
        ltrim(rtrim(login)) as login,
        ltrim(rtrim(drivername)) as drivername,
        vehicle_number,
        strt_datime,
        end_datime,
        eng_time,
        mov_time,
        short_idle_time,
        long_idle_time,
        traveled_miles,
        iff(
            (long_idle_fuel / 1000.0) / (datediff(second, strt_datime, end_datime) + 1 / 3600.00) between 0 and 20,
            long_idle_fuel / 1000.0,
            0
        ) as long_idle_fuel,
        iff(
            (short_idle_fuel / 1000.0) / (datediff(second, strt_datime, end_datime) + 1 / 3600.00) between 0 and 20,
            short_idle_fuel / 1000.0,
            0
        ) as short_idle_fuel,
        iff(
            (gal_fuel / 1000.0) / (datediff(second, strt_datime, end_datime) + 1 / 3600.00) between 0 and 20,
            gal_fuel / 1000.0,
            0
        ) as gal_fuel,
        datediff(second, strt_datime, end_datime) / 3600.00 as segment_hours
    from {{ source('peoplenet', 'performxbydriverdata') }}
    where strt_datime <= end_datime
      and cast(strt_datime as date) >= dateadd(day, -180, cast(end_datime as date))
      and cast(strt_datime as date) > '1900-01-01'
      and datediff(second, strt_datime, end_datime) / 3600.00 < 200
      {% if is_incremental() %}
      and cast(end_datime as date) >= dateadd(day, -10, current_date)
      {% endif %}
),

ccc_unit_service as (
    select
        dim_date.date,
        unit_service.*
    from {{ source('cccfilec', 'unitsrv') }} as unit_service
    left join {{ source('dbo', 'dim_date') }} as dim_date
        on unit_service.srvdat = dim_date.juldate
),

terminal_unit_service as (
    select
        dim_date.date,
        unit_service.*
    from {{ source('cccfilet', 'unitsrv') }} as unit_service
    left join {{ source('dbo', 'dim_date') }} as dim_date
        on unit_service.srvdat = dim_date.juldate
),

enriched_idle_segments as (
    select
        segments.cid,
        segments.login,
        segments.drivername,
        segments.vehicle_number,
        units.unmake as vehicle_make,
        units.unyear as vehicle_model,
        cast(segments.end_datime as date) as date,
        segments.eng_time,
        segments.mov_time,
        segments.short_idle_time,
        segments.long_idle_time,
        segments.segment_hours,
        segments.traveled_miles,
        segments.long_idle_fuel,
        segments.short_idle_fuel,
        segments.gal_fuel,
        iff(trim(segments.cid) = '2626', trim(ccc_service.srvdr1), trim(terminal_service.srvdr1)) as driver1,
        iff(trim(segments.cid) = '2626', trim(ccc_service.srvdr2), trim(terminal_service.srvdr2)) as driver2,
        iff(trim(segments.cid) = '2626', ccc_service.srvdiv, terminal_service.srvdiv) as division,
        iff(trim(segments.cid) = '2626', trim(ccc_service.srvmgr), trim(terminal_service.srvmgr)) as fleet
    from performx_by_driver as segments
    left join ccc_unit_service as ccc_service
        on trim(segments.vehicle_number) = trim(ccc_service.srvunt)
       and cast(segments.end_datime as date) = dateadd(day, -1, ccc_service.date)
    left join terminal_unit_service as terminal_service
        on trim(segments.vehicle_number) = trim(terminal_service.srvunt)
       and cast(segments.end_datime as date) = dateadd(day, -1, terminal_service.date)
    left join {{ source('iesfilec', 'units') }} as units
        on trim(segments.vehicle_number) = trim(units.ununit)
),

aggregated as (
    select
        cid,
        login,
        drivername,
        vehicle_number,
        vehicle_make,
        vehicle_model,
        date,
        sum(eng_time) / 3600.00 as engine_hours,
        sum(mov_time) / 3600.00 as move_hours,
        sum(short_idle_time + long_idle_time) / 3600.00 as idle_hours,
        sum(segment_hours) as segment_hours,
        sum(traveled_miles) as traveled_miles,
        sum(long_idle_fuel + short_idle_fuel) as idle_fuel,
        sum(gal_fuel) as gal_fuel,
        driver1,
        driver2,
        division,
        fleet
    from enriched_idle_segments
    group by
        cid,
        login,
        drivername,
        vehicle_number,
        vehicle_make,
        vehicle_model,
        date,
        driver1,
        driver2,
        division,
        fleet
)

select
    md5(concat_ws('||',
        coalesce(to_varchar(date), ''),
        coalesce(trim(cid), ''),
        coalesce(trim(login), ''),
        coalesce(trim(vehicle_number), ''),
        coalesce(trim(vehicle_make), ''),
        coalesce(to_varchar(vehicle_model), ''),
        coalesce(trim(driver1), ''),
        coalesce(trim(driver2), ''),
        coalesce(trim(division), ''),
        coalesce(trim(fleet), '')
    )) as idle_aggregate_id,
    cid,
    login,
    drivername,
    vehicle_number,
    vehicle_make,
    vehicle_model,
    date,
    engine_hours,
    move_hours,
    idle_hours,
    segment_hours,
    traveled_miles,
    idle_fuel,
    gal_fuel,
    driver1,
    driver2,
    division,
    fleet,
    '0' as cnt
from aggregated
