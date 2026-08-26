{{
    config(
        materialized='view',
        alias='orders'
    )
}}

select
    orara as pickup_area,
    "ORODR#" as order_number,
    orstat as order_status,
    ordate as order_date,
    ortime as order_time,
    case
        when nullif(ordate::varchar, '0') is not null and nullif(ortime::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(
                    dateadd(
                        day,
                        right(ordate::varchar, 3)::integer - 1,
                        date_from_parts(left(ordate::varchar, 4)::integer, 1, 1)
                    ),
                    'YYYY-MM-DD'
                ) || ' ' || lpad(ortime::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as order_datetime,
    orcust as shipper,
    orcons as customer,
    orbill as bill_to,
    orldat as load_at,
    orpdat as early_pickup_date,
    orptim as early_pickup_time,
    case
        when nullif(orpdat::varchar, '0') is not null and nullif(orptim::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(orpdat::varchar, 3)::integer - 1, date_from_parts(left(orpdat::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(orptim::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as early_pickup_datetime,
    orrpik as required_pickup,
    orddat as early_delivery_date,
    ordtim as early_delivery_time,
    case
        when nullif(orddat::varchar, '0') is not null and nullif(ordtim::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(orddat::varchar, 3)::integer - 1, date_from_parts(left(orddat::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(ordtim::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as early_delivery_datetime,
    orrdel as required_delivery,
    orcomc as commodity_code,
    orcomd as commodity_description,
    orinit as initials,
    orcac as customer_phone_area_code,
    orcphn as customer_phone,
    orrac as consignee_phone_area_code,
    orrphn as consignee_phone,
    orctim as calculated_time,
    orwgt as order_weight,
    ortwgt as tare_weight,
    orhook as number_of_hooks,
    orrack as number_of_racks,
    orpllt as number_of_pallets,
    orocty as origin_city,
    orost as origin_state,
    orobea as origin_bea_code,
    orogu as origin_gu_code,
    orosnm as origin_short_name,
    ordcty as destination_city,
    ordst as destination_state,
    ordbea as destination_bea_code,
    ordgu as destination_gu_code,
    ordsnm as destination_short_name,
    ormile as miles,
    orldmi as loaded_miles,
    oremil as empty_miles,
    orrst as route_status,
    "ORSTP#" as number_of_stops_and_comments,
    "ORLD#" as number_of_loads,
    orpdrv as preassigned_tractor,
    "OR#DSP" as number_of_dispatches,
    "ORDSP#" as loads_dispatched_to_destination,
    ortrlr as preload_trailer,
    orestr as estimated_revenue,
    ornwpk as new_pickup_area,
    orinar as destination_area,
    "ORCSH#" as customer_shipping_number,
    "ORCNS#" as consignee_shipping_number,
    ororby as ordered_by,
    "ORLS#" as lease_number,
    orpiec as number_of_pieces,
    orporc as prepaid_or_collect,
    "ORMAN#" as manifest_number,
    orcube as cube_of_load,
    orspec as special,
    orapdt as late_pickup_date,
    oraptm as late_pickup_time,
    case
        when nullif(orapdt::varchar, '0') is not null and nullif(oraptm::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(orapdt::varchar, 3)::integer - 1, date_from_parts(left(orapdt::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(oraptm::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as late_pickup_datetime,
    orapnm as pickup_appointment_name,
    orapin as pickup_appointment_initials,
    oraddt as late_delivery_date,
    oradtm as late_delivery_time,
    case
        when nullif(oraddt::varchar, '0') is not null and nullif(oradtm::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(oraddt::varchar, 3)::integer - 1, date_from_parts(left(oraddt::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(oradtm::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as late_delivery_datetime,
    oradnm as delivery_appointment_name,
    oradin as delivery_appointment_initials,
    orpreq as pallets_required,
    orarr as arrival_date,
    orcpic as consignee_pieces_last_stop,
    orcwgt as consignee_weight_last_stop,
    orshdt as ship_date,
    orshtm as ship_time,
    case
        when nullif(orshdt::varchar, '0') is not null and nullif(orshtm::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(orshdt::varchar, 3)::integer - 1, date_from_parts(left(orshdt::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(orshtm::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as ship_datetime,
    ortmph as high_end_of_temperature,
    ortmpl as low_end_of_temperature,
    oreqty as trailer_type,
    orupdd as last_update_date,
    orupdt as last_update_time,
    case
        when nullif(orupdd::varchar, '0') is not null and nullif(orupdt::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(orupdd::varchar, 3)::integer - 1, date_from_parts(left(orupdd::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(orupdt::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as last_update_datetime,
    orupdi as last_update_initials,

    "ORCO#" as company_number,
    "ORDV#" as division_number,
    "ORTM#" as terminal_number,
    orsel1 as seal_number_1,
    orsel2 as seal_number_2,
    orserv as service_fail_code,
    orcmtm as driver_committment,
    orhazm as hazardous_material_flag,
    oredi as edi_order_flag,
    oredic as edi_stats_complete_flag,
    ordld as driver_load_flag,
    orduld as driver_unload_flag,
    orsdr as signed_delivery_receipt,
    orsdrr as signed_delivery_receipt_required,
    oredmb as edi_message_billing,
    orbboc as bill_before_complete,

    orjit as just_in_time,
    orcded as customer_dedication_code,
    oragnt as agent_code,
    oredfb as edi_bill_code,
    oredio as edi_io_code,

    "ORQUT#" as quote_number,
    oroplm as origin_plus_miles,
    ordplm as destination_plus_miles,
    orccty as current_city,
    orcst as current_state,
    orlcdt as loaded_call_date,
    orecdt as empty_call_date,
    orrato as order_rating_origin,
    orldwg as loaded_weight,
    orlgt as length,
    orhgt as height,
    orwdt as width,
    orpmtf as permit_flag,
    orpcom as permit_complete,
    orlat as pickup_latitude,
    orlong as pickup_longitude,
    orten as tenitive_order_flag,
    orhrs as hours_under_dispatch,
    ormin as minutes_under_dispatch,
    orozn as origin_zone,
    ororg as origin_region,
    ordzn as destination_zone,
    ordrg as destination_region,
    ortbrt as to_be_rated_flag,
    ornzn as new_zone,
    ornrg as new_region,
    ornbea as new_bea_code,
    orngu as new_gu_code,
    orefm as exclude_from_model,
    orcarf as carry_over_flag,
    orutyp as unit_type_requirement,
    orttyp as trailer_type_requirement,
    ordtyp as driver_type_requirement,
    orhazc as hazardous_material_code,
    oroltl as ltl_or_tl_flag_for_order,
    "OR#TYP" as order_type,
    orcnt as count,
    orlutp as load_unload_types,
    ortarp as tarp_pay,
    orclcd as cancel_code,
    ormexf as mexico_flag,
    orthtr as through_trailer_flag,
    orupdp as change_program,
    orfudt as future_use_date,
    orfutm as future_use_time,
    case
        when nullif(orfudt::varchar, '0') is not null and nullif(orfutm::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(orfudt::varchar, 3)::integer - 1, date_from_parts(left(orfudt::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(orfutm::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as future_use_datetime,
    fildte as filler_future_use_date,
    filtim as filler_future_use_time,
    case
        when nullif(fildte::varchar, '0') is not null and nullif(filtim::varchar, '') is not null then
            try_to_timestamp_ntz(
                to_char(dateadd(day, right(fildte::varchar, 3)::integer - 1, date_from_parts(left(fildte::varchar, 4)::integer, 1, 1)), 'YYYY-MM-DD') || ' ' || lpad(filtim::varchar, 4, '0'),
                'YYYY-MM-DD HH24MI'
            )
    end as filler_future_use_datetime,

    orfuf1 as future_use_field_1,
    orfuf2 as future_use_field_2,
    orffl1 as future_use_flag_1,
    orffl2 as future_use_flag_2,
    orffl3 as future_use_flag_3,
    orfil as filler,
    or_supid as subsidiary_legal_entity_id,
    or_dburi as database_record_id,
    or_dbpri as database_parent_record_id,
    try_to_timestamp_ntz(nullif(trim(or_wtims), ''), 'YYYY-MM-DD-HH24.MI.SS.FF6') as write_timestamp,

    or_wuser as writer_user_id,
    to_timestamp_ntz(or_utims, 'YYYY-MM-DD-HH24.MI.SS.FF6') as update_timestamp,

    or_uuser as update_user_id,
    "OR_PORD#" as order_number_prefix,
    "OR_SORD#" as order_number_suffix,
    or_revt1 as revenue_type_1,
    or_revt2 as revenue_type_2,
    or_revt3 as revenue_type_3,
    or_revt4 as revenue_type_4
from {{ source('iesfilec', 'order') }}
