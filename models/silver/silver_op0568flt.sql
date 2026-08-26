{{ config(materialized='view', alias='user_filters') }}

select *
from {{ source('cccfilec', 'op0568flt') }}
