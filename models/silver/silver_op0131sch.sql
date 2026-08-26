{{ config(materialized='view') }}

{% set schedule_source = source('cccfilec', 'op0131sch') %}

select
    {{ select_columns_from_comments(schedule_source, 'source') }}
from {{ schedule_source }} as source
