{{ config(materialized='view') }}

select *
from {{ source('cccfilec', 'op0131sch') }}
