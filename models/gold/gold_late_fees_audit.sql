{{ config(materialized='table') }}

with temp_sam as (
    select
        ficust,
        min(finame) as sam,
        scpgrp
    from {{ source('cccfilec', 'op0568flt') }} as filters
    left join {{ source('cccfilec', 'op0131sch') }} as schedules
        on filters.finame = schedules.schemp
    where firole = 'SAM'
      and ficust <> ''
      and fitype = 'I'
      and fidiv = ''
      and fioarea = ''
      and fiview = ''
    group by ficust, scpgrp
    qualify row_number() over (
        partition by ficust
        order by min(finame)
    ) = 1
),

temp_csr as (
    select
        case
            when ficomp = 'TCC' then 'TCC'
            when fidiv = 'NAT' then 'DRY'
        end as company,
        trim(fioarea) as area,
        min(finame) as csr
    from {{ source('cccfilec', 'op0568flt') }}
    where firole = 'CSR'
      and ficust = ''
      and fitype = 'I'
      and (fidiv = 'NAT' or ficomp = 'TCC')
      and fiview = ''
    group by 1, fioarea
),

temp_zone_mgr as (
    select
        case
            when ficomp = 'TCC' then 'TCC'
            when fidiv = 'NAT' then 'DRY'
        end as company,
        fioarea as area,
        fiozone,
        min(finame) as zone_mgr
    from {{ source('cccfilec', 'op0568flt') }}
    where firole = 'MGR'
      and ficust = ''
      and fitype = 'I'
    group by 1, fiozone, fioarea

),

reason_detail as (
    select
        trim(advance.sa01a) as trip_num,
        advance.sa02a as stop_num,
        advance.sa03a as location_code,
        advance.sa07a as fee_amount,
        timestamp_from_parts(dim_date.date, dim_time.standardtime) as fee_datetime,
        dim_date.date as fee_date,
        rtrim(advance.sa08a) as advance_reason,
        orders.orara as origin_area,
        orders.orstat as status,
        orders.orcust as shipper_code,
        orders.orocty as origin_city,
        orders.orost as origin_state,
        orders.ororg as origin_region,
        orders.orozn as origin_zone,
        orders.ordcty as dest_city,
        orders.ordst as dest_state,
        orders.orinar as dest_area,
        orders.ordrg as dest_region,
        orders.ordzn as dest_zone,
        orders."ORCO#" as company,
        orders.orcomc as commodity,
        load_call_date.date as load_call_date,
        shipper.cuname as shipper_name,
        shipper.cuslmn as sales_team_lean,
        trip.tocsr as area_csr,
        trip.topln as planner,
        trip.toasm,
        trip.toamg as asm_mgr,
        trip.tomgr as ops_mgr,
        trip.tosam as strat_acts_old,
        trip.torep as sales_manager,
        trip.tobda,
        location.cuname as location_name,
        location.cubcty as location_city,
        location.cubst as location_state,
        sam.sam,
        sam.scpgrp,
        csr.csr,
        zone_mgr.zone_mgr
    from {{ source('cccfilec', 'op0516aa') }} as advance
    left join {{ source('dbo', 'dim_date') }} as dim_date
        on advance.sa09a = dim_date.juldate
    left join {{ source('dbo', 'dim_time') }} as dim_time
        on advance.sa10a = dim_time.jultime6

    left join {{ source('iesfilec', 'order') }} as orders
        on trim(advance.sa01a) = orders."ORODR#"
    left join {{ source('dbo', 'dim_date') }} as load_call_date
        on orders.orlcdt = load_call_date.juldate
    left join {{ source('iesfilec', 'custmast') }} as shipper
        on orders.orcust = shipper.cucode
    left join {{ source('cccfilec', 'op0568trp') }} as trip
        on trim(advance.sa01a) = trip.tordr
       and trip.tdisp = '01'
    left join {{ source('iesfilec', 'custmast') }} as location
        on trim(advance.sa03a) = trim(location.cucode)
    left join temp_sam as sam
        on orders.orcust = sam.ficust
    left join temp_csr as csr
        on orders."ORCO#" = csr.company
       and trim(orders.orara) = csr.area
    left join temp_zone_mgr as zone_mgr
        on orders.orara = zone_mgr.area
        or (zone_mgr.area is null and orders.orozn = zone_mgr.fiozone)
    where dim_date.date >= dateadd(month, -24, current_date)
    qualify row_number() over (
        partition by trim(advance.sa01a), rtrim(advance.sa08a)
        order by timestamp_from_parts(dim_date.date, dim_time.standardtime) desc
    ) = 1
),

temp_comment as (
    select
        trim("OCORD#") as comment_trip_number,
        "OCREC#" as comment_record_number,
        left(ocdesc, 9) as comment,
        ocdesc as comment_full,
        case
            when trim(split_part(ocdesc, ':', 2)) in ('A', 'APPROVED') then 'Approved'
            when trim(split_part(ocdesc, ':', 2)) = 'P' then 'Pending'
            when trim(split_part(ocdesc, ':', 2)) in ('D', 'DENIED') then 'Denied'
            when trim(split_part(ocdesc, ':', 2)) = 'N' then 'None'
            else 'Needs Fixed'
        end as late_fee_approval
    from {{ source('iesfilec', 'comment') }}
    where octyp = 'B'
      and left(ocdesc, 9) = 'Cust Cont'
    qualify row_number() over (
        partition by trim("OCORD#")
        order by "OCREC#", "OCREC#" desc
    ) = 1
),

temp_comment_late_fee as (
    select
        trim("OCORD#") as comment_trip_number_late_fee,
        ocdesc as comment_advanced_reason_late_fee_desc,
        trim(split_part(ocdesc, ':', 2)) as comment_late_event
    from {{ source('iesfilec', 'comment') }}
    where octyp = 'B'
      and trim(ocdesc) ilike 'Advance Reason:%'
    qualify row_number() over (
        partition by trim("OCORD#"), trim(split_part(ocdesc, ':', 2))
        order by "OCREC#" desc
    ) = 1
),

bill_pay_base as (
    select
        trim(order_number) as bp_order_number,
        stop_number,
        line_amount,
        case
            when event_name = 'LATE FEE/RESCHEDULE' then 'LATE FEE'
            when event_name = 'LAYOVER (BILL ONLY)' then 'LAYOVER'
            when event_name = 'LUMPER THIRD PARTY' then 'LUMPER'
            else event_name
        end as event_name,
        line_description,
        trim(split_part(line_description, ':', 1)) as bp_desc,
        approval_status,
        trim(split_part(line_description, ':', 2)) as bp_approval_desc
    from {{ source('cccfilec', 'op0710bp') }}
    where trim(split_part(line_description, ':', 1)) in ('Approval Status', 'Chargeback Customer')
    qualify row_number() over (
        partition by trim(order_number), event_name
        order by trim(order_number), update_timestamp desc
    ) = 1
),

bill_approval_base as (
    select
        trim(order_number) as bp_order_number,
        case
            when event_name = 'LATE FEE/RESCHEDULE' then 'LATE FEE'
            when event_name = 'LAYOVER (BILL ONLY)' then 'LAYOVER'
            when event_name = 'LUMPER THIRD PARTY' then 'LUMPER'
            else event_name
        end as event_name,
        form_data as customer_approval_status,
        trim(split_part(line_description, ':', 2)) as bp_approval_status_desc
    from {{ source('cccfilec', 'op0710bp') }}
    where trim(split_part(line_description, ':', 1)) = 'Customer Approval Status'
),

temp_bill_pay as (
    select
        bill_pay.bp_order_number as bill_pay_order_number,
        bill_pay.event_name as bill_pay_event,
        bill_pay.bp_desc as bill_pay_description,
        bill_pay.bp_approval_desc as bill_pay_approval_desc,
        case
            when bill_pay.bp_desc = 'Approval Status' then case
                when bill_pay.bp_approval_desc in ('NO', 'DENIED') then 'Denied'
                when bill_pay.bp_approval_desc in ('YES', 'A', 'APPROVED') then 'Approved'
                when bill_pay.bp_approval_desc in ('P', 'PENDING', '(BP)') then 'Pending'
                else bill_pay.bp_approval_desc
            end
            when bill_pay.bp_desc ilike 'Chargeback Customer' then case
                when approval.customer_approval_status = 'A' then 'Approved'
                when approval.customer_approval_status = 'D' then 'Denied'
                when approval.customer_approval_status = 'P' then 'Pending'
                when approval.customer_approval_status = 'N' then 'None'
                when approval.customer_approval_status is null and bill_pay.approval_status = 'N' then 'None'
                when approval.customer_approval_status is null and bill_pay.approval_status = 'NO' then 'Denied'
            end
            else ''
        end as bill_pay_approval,
        case
            when approval.customer_approval_status = 'P' then 'PENDING'
            when approval.customer_approval_status = 'D' then 'DENIED'
            when approval.customer_approval_status = 'A' then 'APPROVED'
            when approval.customer_approval_status = 'N' then 'NO B COMMENT'
            else 'NO B COMMENT'
        end as customer_approval_status,
        approval.customer_approval_status as customer_approval_status_code,
        approval.bp_approval_status_desc,
        bill_pay.line_amount as bill_pay_amount
    from bill_pay_base as bill_pay
    left join bill_approval_base as approval
        on bill_pay.bp_order_number = approval.bp_order_number
       and bill_pay.event_name = approval.event_name
    qualify row_number() over (
        partition by bill_pay.bp_order_number, bill_pay.event_name
        order by bill_pay.bp_desc, bill_pay.bp_approval_desc desc
    ) = 1
),

chargeback as (
    select
        bp_order_number as order_number,
        stop_number,
        event_name,
        bp_approval_desc as chargeback_customer
    from bill_pay_base
    where bp_desc = 'Chargeback Customer'
)

select distinct
    md5(concat_ws('||', coalesce(reason_detail.trip_num, ''), coalesce(to_varchar(reason_detail.stop_num), ''), coalesce(reason_detail.advance_reason, ''), coalesce(to_varchar(reason_detail.fee_datetime), ''))) as late_fee_audit_id,

    reason_detail.*,
    temp_comment.comment_trip_number,
    temp_comment.comment_record_number,
    temp_comment.comment_full,
    temp_comment.comment,
    temp_comment.late_fee_approval,
    temp_comment_late_fee.comment_advanced_reason_late_fee_desc,
    coalesce(trim(split_part(temp_comment_late_fee.comment_advanced_reason_late_fee_desc, ':', 2)), 'No Adv Reason') as comment_advanced_reason_late_fee,
    temp_bill_pay.bill_pay_event,
    temp_bill_pay.bill_pay_description,
    temp_bill_pay.bill_pay_approval_desc,
    temp_bill_pay.bill_pay_approval,
    temp_bill_pay.customer_approval_status,
    temp_bill_pay.customer_approval_status_code,
    temp_bill_pay.bp_approval_status_desc,
    temp_bill_pay.bill_pay_amount,
    late_fees_billing.consignee,
    late_fees_billing.load_date,
    late_fees_billing.empty_date,
    chargeback.chargeback_customer
from reason_detail
left join temp_comment
    on reason_detail.trip_num = temp_comment.comment_trip_number
left join temp_comment_late_fee
    on reason_detail.trip_num = temp_comment_late_fee.comment_trip_number_late_fee
   and reason_detail.advance_reason = temp_comment_late_fee.comment_late_event
left join temp_bill_pay
    on reason_detail.trip_num = temp_bill_pay.bill_pay_order_number
   and trim(reason_detail.advance_reason) = trim(temp_bill_pay.bill_pay_event)
left join {{ ref('gold_late_fees_billing') }} as late_fees_billing
    on reason_detail.trip_num = late_fees_billing.trip
   and reason_detail.fee_amount = late_fees_billing.fee
left join chargeback
    on reason_detail.trip_num = chargeback.order_number
   and reason_detail.stop_num = chargeback.stop_number
   and temp_bill_pay.bill_pay_event = chargeback.event_name
