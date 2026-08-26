{{ config(materialized='view', alias='billing') }}

select *
from {{ source('iesfilec', 'billing') }}
