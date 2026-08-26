INSERT OVERWRITE INTO PROD_DIG.dbo.late_fees_billing
/* Get Billing Data */
WITH billing_detail AS (
 SELECT 
        b1.bicomm AS bicomm,
        b1.biodr AS biodr,
        b1.bidesc AS bidesc,
        b1.biamt AS biamt,
        CASE 
            WHEN b1.bicomm = 'LOTO' THEN 1 
            WHEN b1.bicomm = 'LOTC' THEN 90 
            ELSE NULL 
        END AS stop
    FROM (
        SELECT 
            biodr,  
            bicomm, 
            bidesc, 
            biamt
        FROM IESFILEC.BILLING
        WHERE bicomm LIKE 'LOT%'
        ) b1
),


-----------------------------------------------------------------------------------------------------------------
/* Pull Advanced Reason and Billing */
billing_fees AS (
SELECT 
    t1.sa01a AS trip,
    t1.sa02a AS stop,
    t1.sa07a AS fee,
    RTRIM(t1.sa08a) AS advance_reason,
    t2.orcust AS shipper_code,
    t2.orcons AS consignee,
    -- t2.orlcdate AS load_date,
    D1.date as load_date,
    t2.orost AS origin_state,
    t2.ordst AS dest_state,
    t2."ORCO#" AS company,
    -- t2.orecdate AS empty_date,
    D2.date as empty_date,
    t2.orcomc AS commodity,
    t3.biamt AS fee_charged_to_customer_old,
    t4.ciname AS dest_city,
    t5.ciname AS origin_city,
    t6.socust AS stop_code,
    -- t6.early_appt_datetime AS early_appt_datetime,
    -- t6.late_appt_datetime AS late_appt_datetime,
    TIMESTAMP_FROM_PARTS(D3.DATE, D5.STANDARDTIME) AS early_appt_datetime,
    TIMESTAMP_FROM_PARTS(D4.DATE, D6.STANDARDTIME) AS late_appt_datetime,
    t7.cuname AS stop_name
FROM CCCFILEC.OP0516AA t1
LEFT JOIN IESFILEC."ORDER" t2 ON t1.sa01a = t2."ORODR#"
LEFT JOIN DBO.DIM_DATE D1 ON t2.orlcdt = D1.juldate
LEFT JOIN DBO.DIM_DATE D2 ON t2.orecdt = D2.juldate
LEFT JOIN billing_detail t3 ON t1.sa01a = t3.biodr AND t1.sa02a = t3.stop

LEFT JOIN IESFILEC.CITIES t4 ON t2.ordst = t4.cist AND TRIM(t2.ordcty) = TRIM(t4.cicty)
LEFT JOIN IESFILEC.CITIES t5 ON t2.orost = t5.cist AND TRIM(t2.orocty) = TRIM(t5.cicty)
LEFT JOIN IESFILEC.STOPOFF t6 ON t1.sa01a = t6.soord AND t1.sa02a = t6."SOSTP#"
LEFT JOIN DBO.DIM_DATE D3 ON t6.SOADT1 = D3.juldate --Appt Early date
LEFT JOIN DBO.DIM_DATE D4 ON t6.SOADT2 = D4.juldate --Appt Late Date
LEFT JOIN DBO.DIM_TIME D5 ON t6.SOATM1 = D5.JULTIME4
LEFT JOIN DBO.DIM_TIME D6 ON t6.SOATM2 = D6.JULTIME4
LEFT JOIN IESFILEC.CUSTMAST t7 ON t6.socust = t7.cucode

WHERE t1.sa08a = 'LATE FEE'
ORDER BY trip
)




------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- CREATE OR REPLACE TABLE prod_dig.dbo.late_fees_billing AS 
-- Select *
-- from dbo.billing_fees


--TRUNCATE TABLE PROD_DIG.dbo.late_fees_billing;
--INSERT INTO PROD_DIG.dbo.late_fees_billing 
Select *
from billing_fees;
