{{
    config(
        materialized='view'
    )
}}

select
    soord as order_number,
    "SOSTP#" as stop_number,
    sotype as stop_type,
    "SOREC#" as record_number,
    socust as customer_code,
    soctyc as city_code,
    sost as state_code,
    soac as phone_area_code,
    sophnm as phone_number,
    socont as contact_name,
    soecd1 as early_close_date_1,
    soecd2 as early_close_date_2,
    solsta as stop_status,
    soeda as early_appointment_date,
    soeta as early_appointment_time,
    case
        when nullif(soeda::varchar, '0') is not null and nullif(soeta::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(soeda::varchar, 3)::integer - 1, date_from_parts(left(soeda::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(soeta::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as early_appointment_datetime,
    soadt1 as appointment_date_1,
    soadt2 as appointment_date_2,
    soatm1 as appointment_time_1,
    soatm2 as appointment_time_2,
    soardt as arrival_date,
    soartm as arrival_time,
    case
        when nullif(soardt::varchar, '0') is not null and nullif(soartm::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(soardt::varchar, 3)::integer - 1, date_from_parts(left(soardt::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(soartm::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as arrival_datetime,
    soludt as load_unload_date,
    solutm as load_unload_time,
    case
        when nullif(soludt::varchar, '0') is not null and nullif(solutm::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(soludt::varchar, 3)::integer - 1, date_from_parts(left(soludt::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(solutm::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as load_unload_datetime,
    soappr as appointment_required_flag,
    socsid as customer_stop_id,
    sosel1 as seal_number_1,
    sosel2 as seal_number_2,
    sowgt as stop_weight,
    sopiec as number_of_pieces,
    soum as unit_of_measure,
    sostr as street_address,
    sodept as department,
    soplon as longitude,
    soplof as latitude,
    sodlu as driver_load_unload_flag,
    sounit as unit_number,
    sotrl1 as trailer_number,
    soreas as reason_code,
    socomp as company_number,
    sodisp as dispatch_number,
    soapmi as appointment_initials,
    soapmd as appointment_date,
    soapmt as appointment_time,
    case
        when nullif(soapmd::varchar, '0') is not null and nullif(soapmt::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(soapmd::varchar, 3)::integer - 1, date_from_parts(left(soapmd::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(soapmt::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as appointment_datetime,
    sospec as special_instructions,
    soaptm as appointment_time_minutes,
    socrtd as created_date,
    socrtt as created_time,
    socrtu as created_user_id,
    socrtp as created_program,
    sochgd as changed_date,
    sochgt as changed_time,
    sochgu as changed_user_id,
    sochgp as changed_program,
    so_supid as subsidiary_legal_entity_id,
    so_dburi as database_record_id,
    so_dbpri as database_parent_record_id,
    try_to_timestamp_ntz(nullif(trim(so_wtims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as write_timestamp,
    so_wuser as writer_user_id,
    to_timestamp_ntz(so_utims, 'YYYY-MM-DD-HH24.MI.SS.FF6') as update_timestamp,
    so_uuser as update_user_id,
    "SO_PORD#" as order_number_prefix,
    "SO_SORD#" as order_number_suffix,
    so_revt1 as revenue_type_1,
    so_revt2 as revenue_type_2,
    so_revt3 as revenue_type_3,
    so_revt4 as revenue_type_4
from {{ source('iesfilec', 'stopoff') }}
