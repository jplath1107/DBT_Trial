{{ config(materialized='view') }}

select *
from {{ source('dbo', 'late_fees_billing') }}
