 WITH temp_sam AS (
        SELECT
            ficust,
            MIN(finame) AS sam,
            scpgrp
        FROM
            CCCFILEC.OP0568FLT t1
            LEFT JOIN CCCFILEC.OP0131SCH t2 ON t1.finame = t2.schemp
        WHERE
            firole = 'SAM'
            AND ficust <> ''
            AND fitype = 'I'
            AND fidiv = ''
            AND fioarea = ''
            AND fiview = ''
        GROUP BY
            ficust,
            scpgrp QUALIFY ROW_NUMBER() OVER (
                PARTITION BY ficust
                ORDER BY
                    MIN(finame)
            ) = 1
    )
    /* 2 - Get Area CSR */,
    temp_csr AS (
        SELECT
            CASE
                WHEN ficomp = 'TCC' THEN 'TCC'
                WHEN fidiv = 'NAT' THEN 'DRY'
            END AS company,
            trim(fioarea) AS area,
            MIN(finame) AS csr
        FROM
            CCCFILEC.OP0568FLT
        WHERE
            firole = 'CSR'
            AND ficust = ''
            AND fitype = 'I'
            AND (
                fidiv = 'NAT'
                OR ficomp = 'TCC'
            )
            AND fiview = ''
        GROUP BY
            CASE
                WHEN ficomp = 'TCC' THEN 'TCC'
                WHEN fidiv = 'NAT' THEN 'DRY'
            END,
            fioarea
    )
    /* 3 - Get Zone Manager */,
    temp_zone_mgr AS (
        SELECT
            CASE
                WHEN ficomp = 'TCC' THEN 'TCC'
                WHEN fidiv = 'NAT' THEN 'DRY'
            END AS company,
            fioarea AS area,
            fiozone,
            MIN(finame) AS zone_mgr
        FROM
            CCCFILEC.OP0568FLT t1
        WHERE
            firole = 'MGR'
            AND ficust = ''
            AND fitype = 'I'
        GROUP BY
            CASE
                WHEN ficomp = 'TCC' THEN 'TCC'
                WHEN fidiv = 'NAT' THEN 'DRY'
            END,
            fiozone,
            fioarea,
            finame
    )
    /* 4 - Trip and Order detail */,
    reason_detail AS (
        SELECT
            TRIM(t1.sa01a) AS trip_num,
            t1.sa02a AS stop_num,
            t1.sa03a AS location_code,
            t1.sa07a AS fee_amount,
            TIMESTAMP_FROM_PARTS(t2.date, tt2.STANDARDTIME) AS fee_datetime,
            t2.date AS fee_date,
            RTRIM(t1.sa08a) AS advance_reason,
            -- ROW_NUMBER() OVER (
            --     PARTITION BY TRIM(t1.sa01a), RTRIM(t1.sa08a)
            --     ORDER BY TIMESTAMP_FROM_PARTS(t2.date, tt2.STANDARDTIME) DESC) AS ROW_NUMBER,
            t3.orara AS origin_area,
            t3.orstat AS status,
            t3.orcust AS shipper_code,
            t3.orocty AS origin_city,
            t3.orost AS origin_state,
            t3.ororg AS origin_region,
            t3.orozn AS origin_zone,
            t3.ordcty AS dest_city,
            t3.ordst AS dest_state,
            t3.orinar AS dest_area,
            t3.ordrg AS dest_region,
            t3.ordzn AS dest_zone,
            t3."ORCO#" AS company,
            t3.orcomc AS commodity,
            d1.date AS load_call_date,
            t4.cuname AS shipper_name,
            t4.cuslmn AS sales_team_lean,
            t5.tocsr AS area_csr,
            t5.topln AS planner,
            t5.toasm,
            t5.toamg AS asm_mgr,
            t5.tomgr AS ops_mgr,
            t5.tosam AS strat_acts_old,
            t5.torep AS sales_manager,
            t5.tobda,
            t6.cuname AS location_name,
            t6.cubcty AS location_city,
            t6.cubst AS location_state,
            t7.sam,
            t7.scpgrp,
            t8.csr,
            t9.zone_mgr -- ,T1.*
        FROM
            cccfilec.OP0516AA t1
            LEFT JOIN DBO.DIM_DATE t2 ON t1.sa09a = t2.juldate
            LEFT JOIN DBO.DIM_TIME tt2 ON t1.SA10A = tt2.JULTIME6
            LEFT JOIN IESFILEC."ORDER" t3 ON TRIM(t1.sa01a) = t3."ORODR#"
            LEFT JOIN DBO.DIM_DATE d1 ON t3.orlcdt = d1.juldate
            LEFT JOIN IESFILEC.CUSTMAST t4 ON t3.orcust = t4.cucode
            LEFT JOIN CCCFILEC.OP0568TRP t5 ON TRIM(t1.sa01a) = t5.tordr
            AND '01' = t5.tdisp
            LEFT JOIN IESFILEC.CUSTMAST t6 ON TRIM(t1.sa03a) = trim(t6.cucode)
            LEFT JOIN temp_sam t7 ON t3.orcust = t7.ficust
            LEFT JOIN temp_csr t8 ON t3."ORCO#" = t8.company
            AND trim(t3.orara) = t8.area
            LEFT JOIN temp_zone_mgr t9 ON t3.orara = t9.area
            OR (
                t9.area IS NULL
                AND t3.orozn = t9.fiozone
            )
        WHERE
            1 = 1 -- AND RTRIM(t1.sa08a) ILIKE 'LATE FEE'
            AND t2.date >= DATEADD(MONTH, -24, CURRENT_DATE) -- AND TRIM(t1.sa01a) in ('4509793','4528262','4683224','4349371','4349669','4354002')
            QUALIFY ROW_NUMBER() OVER (
                PARTITION BY TRIM(t1.sa01a),
                RTRIM(t1.sa08a)
                ORDER BY
                    TIMESTAMP_FROM_PARTS(t2.date, tt2.STANDARDTIME) DESC
            ) = 1 -- ORDER BY TRIM(t1.sa01a), TIMESTAMP_FROM_PARTS(t2.date, tt2.STANDARDTIME) ;
    )
    /* 5 - Comments for Cust Cont, type B */,
    temp_comment AS (
        SELECT
            TRIM(t2."OCORD#") AS comment_trip_number,
            t2."OCREC#" AS comment_record_number,
            t2.octyp,
            LEFT(t2.ocdesc, 9) AS comment,
            t2.ocdesc AS comment_full,
            TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) AS comment_code,
            -- RIGHT(TRIM(t2.ocdesc), 2) AS comment_code,
            CASE
                -- WHEN LEFT(t2.ocdesc, 9) IS NULL THEN 'No Comment'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%PENDING%' THEN 'Pending'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%DENIED%' THEN 'Denied'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%REJECTED%' THEN 'Rejected'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%SALES%' THEN 'Sales'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%BILLING%' THEN 'Billing'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%WEBSITE%' THEN 'Website'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%APPROVED%' THEN 'Approved'
                -- WHEN LEFT(t2.ocdesc, 9) ILIKE '%APPRV%' THEN 'Approved'
                WHEN TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) = 'A' THEN 'Approved'
                WHEN TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) = 'APPROVED' THEN 'Approved'
                WHEN TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) = 'P' THEN 'Pending'
                WHEN TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) = 'D' THEN 'Denied'
                WHEN TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) = 'DENIED' THEN 'Denied'
                WHEN TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) = 'N' THEN 'None'
                ELSE 'Needs Fixed'
            END AS late_fee_approval,
            t2.*
        FROM
            IESFILEC.COMMENT t2
        WHERE
            t2.octyp = 'B'
            AND LEFT(t2.ocdesc, 9) = 'Cust Cont' QUALIFY ROW_NUMBER() OVER (
                PARTITION BY TRIM(t2."OCORD#")
                ORDER BY
                    t2."OCREC#",
                    t2."OCREC#" desc
            ) = 1 --     AND TRIM(t2."OCORD#") in ('4509793','4528262','4683224')
            -- order by trim(t2."OCORD#") desc
    )
    /* 5A - Comments for Cust Cont, type B */,
    temp_comment_late_fee AS (
        SELECT
            TRIM(t2."OCORD#") AS comment_trip_number_late_fee,
            t2."OCREC#" AS comment_record_number_late_fee,
            t2.ocdesc AS comment_advanced_reason_late_fee_desc,
            TRIM(SPLIT_PART(t2.ocdesc, ':', 2)) AS comment_late_event -- t2.octyp,
        FROM
            IESFILEC.COMMENT t2
        WHERE
            t2.octyp = 'B' -- AND trim(t2.ocdesc) ILIKE 'Advance Reason: LATE FEE%'
            AND trim(t2.ocdesc) ILIKE 'Advance Reason:%' -- UPDATED 2026-07-07 th
            -- and TRIM(t2."OCORD#") in ('4509793','4528262','4683224')
            QUALIFY ROW_NUMBER() OVER (
                PARTITION BY TRIM(t2."OCORD#"),
                TRIM(SPLIT_PART(t2.ocdesc, ':', 2))
                ORDER BY
                    t2."OCREC#" DESC
            ) = 1 -- ORDER BY TRIM(t2."OCORD#"), t2."OCREC#"
    )
    /* 6 - Order Bill/Pay File (combined bill_pay + chargeback in single scan) */,
    bill_pay_base AS (
        SELECT
            TRIM(order_number) AS bp_order_number,
            stop_number,
            line_amount,
            -- event_name,
            case
                when event_name = 'LATE FEE/RESCHEDULE' then 'LATE FEE'
                when event_name = 'LAYOVER (BILL ONLY)' then 'LAYOVER'
                when event_name = 'LUMPER THIRD PARTY' then 'LUMPER'
                else event_name
            end as event_name,
            line_description,
            TRIM(SPLIT_PART(line_description, ':', 1)) AS bp_desc,
            approval_status,
            TRIM(SPLIT_PART(line_description, ':', 2)) AS bp_approval_desc,
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(order_number),
                event_name
                ORDER BY
                    TRIM(order_number),
                    UPDATE_TIMESTAMP DESC
            ) AS ROW_NUM -- ,*
        FROM
            cccfilec.op0710bp
        WHERE
            TRIM(SPLIT_PART(line_description, ':', 1)) IN ('Approval Status', 'Chargeback Customer') -- and TRIM(order_number) in ('4509793','4528262','4683224','4349371','4349669','4354002')
            QUALIFY ROW_NUMBER() OVER (
                PARTITION BY TRIM(order_number),
                event_name
                ORDER BY
                    TRIM(order_number),
                    UPDATE_TIMESTAMP DESC
            ) = 1 -- ORDER BY TRIM(order_number), EVENT_LINE, UPDATE_TIMESTAMP
    )
    /* 6A - Order Bill/Pay File (combined bill_pay + chargeback in single scan) */
    /* Customer Approval Status is P (Pending) or N (None).  The trip should be shown in the report. */
    /* Customer Approval Status is A (Approved) or D (Denied).  The trip should NOT be shown on the report.  */,
    bill_approval_base AS (
        SELECT
            TRIM(order_number) AS bp_order_number,
            stop_number,
            -- event_name,
            case
                when event_name = 'LATE FEE/RESCHEDULE' then 'LATE FEE'
                when event_name = 'LAYOVER (BILL ONLY)' then 'LAYOVER'
                when event_name = 'LUMPER THIRD PARTY' then 'LUMPER'
                else event_name
            end as event_name,
            line_description,
            line_amount,
            approval_status,
            form_data as customer_approval_status,
            TRIM(SPLIT_PART(line_description, ':', 1)) AS bp_status_desc,
            TRIM(SPLIT_PART(line_description, ':', 2)) AS bp_approval_status_desc
        FROM
            cccfilec.op0710bp
        WHERE
            1 = 1
            and TRIM(SPLIT_PART(line_description, ':', 1)) IN ('Customer Approval Status') -- and TRIM(order_number) = '4586174'
            -- ORDER by order_number DESC
    ),
    temp_bill_pay AS (
        SELECT
            t1.bp_order_number AS bill_pay_order_number,
            t1.event_name AS bill_pay_event,
            t1.bp_desc AS bill_pay_description,
            t1.bp_approval_desc AS bill_pay_approval_desc,
            t1.approval_status,
            t1.line_description,
            CASE
                WHEN t1.approval_status = 'A' THEN 'Approved'
                WHEN t1.approval_status = 'D' THEN 'Denied'
                WHEN t1.approval_status = 'P' THEN 'Pending'
                WHEN t1.approval_status = 'N' THEN 'None'
            END as approval_status_base,
            CASE
                WHEN t1.bp_desc = 'Approval Status' THEN CASE
                    WHEN t1.bp_approval_desc = 'NO' THEN 'Denied'
                    WHEN t1.bp_approval_desc = 'DENIED' THEN 'Denied'
                    WHEN t1.bp_approval_desc = 'YES' THEN 'Approved'
                    WHEN t1.bp_approval_desc = 'A' THEN 'Approved'
                    WHEN t1.bp_approval_desc = 'APPROVED' THEN 'Approved'
                    WHEN t1.bp_approval_desc = 'P' THEN 'Pending'
                    WHEN t1.bp_approval_desc = 'PENDING' THEN 'Pending'
                    WHEN t1.bp_approval_desc = '(BP)' THEN 'Pending'
                    ELSE t1.bp_approval_desc
                END
                WHEN t1.bp_desc ILIKE 'Chargeback Customer' THEN -- WHEN t1.line_description ILIKE 'Chargeback Customer                : YES%' THEN
                CASE
                    WHEN t2.customer_approval_status = 'A' THEN 'Approved'
                    WHEN t2.customer_approval_status = 'D' THEN 'Denied'
                    WHEN t2.customer_approval_status = 'P' THEN 'Pending'
                    WHEN t2.customer_approval_status = 'N' THEN 'None'
                    WHEN t2.customer_approval_status IS NULL
                    AND t1.approval_status = 'N' THEN 'None'
                    WHEN t2.customer_approval_status IS NULL
                    AND t1.approval_status = 'NO' THEN 'Denied'
                END -- WHEN t1.line_description ILIKE 'Chargeback Customer                : NO%' THEN t1.bp_approval_desc
                ELSE ''
            END AS bill_pay_approval,
            t2.customer_approval_status AS customer_approval_status_code,
            t2.bp_approval_status_desc,
            CASE
                WHEN t2.customer_approval_status = 'P' THEN 'PENDING'
                WHEN t2.customer_approval_status = 'D' THEN 'DENIED'
                WHEN t2.customer_approval_status = 'A' THEN 'APPROVED'
                WHEN t2.customer_approval_status = 'N' THEN 'NO B COMMENT'
                ELSE 'NO B COMMENT'
            END AS customer_approval_status,
            t1.line_amount AS bill_pay_amount -- ,ROW_NUMBER() OVER (
            --     PARTITION BY t1.bp_order_number,
            --     t1.event_name
            --     ORDER BY
            --         t1.bp_desc,
            --         t1.bp_approval_desc DESC
            --     ) AS ROW_NUM
        FROM
            bill_pay_base t1
            left join bill_approval_base t2 on t1.bp_order_number = t2.bp_order_number
            AND T1.event_name = t2.event_name -- where t1.bp_order_number in ('4509793','4528262')
            QUALIFY ROW_NUMBER() OVER (
                PARTITION BY t1.bp_order_number,
                t1.event_name
                ORDER BY
                    t1.bp_desc,
                    t1.bp_approval_desc DESC
            ) = 1 -- ORDER BY t1.bp_order_number;
    ),
    chargeback AS (
        SELECT
            bp_order_number AS order_number,
            stop_number,
            event_name,
            line_amount,
            bp_approval_desc AS chargeback_customer
        FROM
            bill_pay_base
        WHERE
            bp_desc = 'Chargeback Customer'
    )
    /* 7 - Pull tables together */
SELECT
    t1.*,
    tc.comment_trip_number,
    tc.comment_record_number,
    tc.comment_full,
    tc.comment,
    tc.late_fee_approval,
    lf.comment_advanced_reason_late_fee_desc,
    CASE
        WHEN lf.comment_advanced_reason_late_fee_desc IS NULL THEN 'No Adv Reason' -- ELSE 'Adv Reason:Late Fee'
        ELSE TRIM(
            SPLIT_PART(lf.comment_advanced_reason_late_fee_desc, ':', 2)
        )
    END AS comment_advanced_reason_late_fee,
    tb.bill_pay_event,
    tb.bill_pay_description,
    tb.bill_pay_approval_desc,
    tb.bill_pay_approval,
    -- CASE
    --     WHEN tb.bill_pay_approval = 'A' THEN 'Approved'
    --     WHEN tb.bill_pay_approval = 'APPROVED' THEN 'Approved'
    --     WHEN tb.bill_pay_approval = 'YES' THEN 'Approved'
    --     WHEN tb.bill_pay_approval = 'D' THEN 'Denied'
    --     WHEN tb.bill_pay_approval = 'DENIED' THEN 'Denied'
    --     WHEN tb.bill_pay_approval = 'NO' THEN 'Denied'
    --     WHEN tb.bill_pay_approval = 'P' THEN 'Pending'
    --     WHEN tb.bill_pay_approval = 'PENDING' THEN 'Pending'
    --     WHEN tb.bill_pay_approval = 'N' THEN 'None'
    --     WHEN tb.bill_pay_approval = 'None' THEN 'None'
    -- END
    tb.customer_approval_status,
    tb.customer_approval_status_code,
    tb.bp_approval_status_desc,
    tb.bill_pay_amount,
    t2.consignee,
    t2.load_date,
    t2.empty_date,
    cb.chargeback_customer -- SELECT T1.trip_num, T1.ADVANCE_REASON, TC.*,LF.*, tb.*, cb.*
FROM
    reason_detail t1
    LEFT JOIN temp_comment tc ON t1.trip_num = tc.comment_trip_number
    LEFT JOIN temp_comment_late_fee LF ON T1.trip_num = LF.comment_trip_number_late_fee
    AND T1.advance_reason = LF.comment_late_event
    LEFT JOIN temp_bill_pay tb ON t1.trip_num = tb.bill_pay_order_number
    and trim(t1.advance_reason) = trim(tb.bill_pay_event)
    LEFT JOIN DBO.LATE_FEES_BILLING t2 ON t1.trip_num = t2.trip
    AND t1.fee_amount = t2.fee
    LEFT JOIN chargeback cb ON t1.trip_num = cb.order_number
    AND t1.stop_num = cb.stop_number
    AND tb.bill_pay_event = cb.event_name -- WHERE t1.trip_num in ('4509793','4528262','4683224')
ORDER BY
    t1.trip_num DESC,
    T1.advance_reason;
