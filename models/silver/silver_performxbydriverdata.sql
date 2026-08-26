{{ config(materialized='view') }}

select *
from {{ source('peoplenet', 'performxbydriverdata') }}
