{{ config(materialized='view', alias='date_dimension') }}

select *
from {{ source('dbo', 'dim_date') }}
