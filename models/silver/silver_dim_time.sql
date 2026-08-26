{{ config(materialized='view', alias='time_dimension') }}

select *
from {{ source('dbo', 'dim_time') }}
