{{ config(materialized='view', alias='legacy_late_fees_billing') }}

select *
from {{ source('dbo', 'late_fees_billing') }}
