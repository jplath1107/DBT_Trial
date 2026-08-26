{{ config(materialized='view', alias='schedule_assignments') }}

select *
from {{ source('cccfilec', 'op0131sch') }}
