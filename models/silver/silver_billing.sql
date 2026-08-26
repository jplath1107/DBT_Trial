{{ config(materialized='view') }}

select *
from {{ source('iesfilec', 'billing') }}
