{{ config(materialized='view', alias='cities') }}

select *
from {{ source('iesfilec', 'cities') }}
