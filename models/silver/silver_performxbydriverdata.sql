{{ config(materialized='view', alias='driver_performance') }}

select *
from {{ source('peoplenet', 'performxbydriverdata') }}
