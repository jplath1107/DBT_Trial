{{ config(materialized='view', alias='trip_dispatch') }}

select *
from {{ source('cccfilec', 'op0568trp') }}
