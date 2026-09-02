{{ config(materialized='view') }}

select
    "OCORD#" as order_number,
    "OCREC#" as record_number,
    octyp as type_p_s_c_b,
    ocloc as dest_or_location,
    ocdesc as description,
    ocdlt as dlt_code,
    ocfil as ocfil,
    ocdate as comment_date_raw,
    {{ julian_date('ocdate') }} as comment_date,
    ocinit as initials,
    occucd as customer,
    occuty as customer_type,
    occrtd as create_date,
    occrtt as create_time,
    {{ julian_datetime_seconds('occrtd', 'occrtt') }} as created_datetime,
    occrtu as create_user,
    occrtp as create_pgm,
    occhgd as change_date,
    occhgt as change_time,
    {{ julian_datetime_seconds('occhgd', 'occhgt') }} as changed_datetime,
    occhgu as change_user,
    occhgp as change_pgm,
    oc_supid as subsidiary_legal_entity_id,
    oc_dburi as db_record_id,
    oc_dbpri as db_parent_record_id,
    oc_wtims as write_timestamp_raw,
    try_to_timestamp_ntz(
        nullif(trim(oc_wtims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as write_timestamp,
    oc_wuser as writer_userid,
    oc_utims as update_timestamp_raw,
    try_to_timestamp_ntz(
        nullif(trim(oc_utims), ''),
        'YYYY-MM-DD-HH24.MI.SS.FF6'
    ) as update_timestamp,
    oc_uuser as update_userid,
    "OC_PORD#" as order_prefix,
    "OC_SORD#" as order_suffix,
    oc_revt1 as revenue_type_1,
    oc_revt2 as revenue_type_2,
    oc_revt3 as revenue_type_3,
    oc_revt4 as revenue_type_4
from {{ source('iesfilec', 'comment') }}
