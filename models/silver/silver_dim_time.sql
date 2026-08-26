{{ config(materialized='view') }}

select *
from {{ source('dbo', 'dim_time') }}
