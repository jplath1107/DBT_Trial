{{ config(materialized='view', alias='order_comments') }}

select
    source.*,
    {{ julian_date('source.ocdate') }} as comment_date,
    {{ julian_datetime('source.occrtd', 'source.occrtt') }} as created_datetime,
    {{ julian_datetime('source.occhgd', 'source.occhgt') }} as changed_datetime
from {{ source('iesfilec', 'comment') }} as source
