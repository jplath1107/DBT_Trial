{{ config(materialized='view') }}

select
    source.*,
    {{ julian_date('source.ocdate') }} as comment_date,
    {{ julian_datetime_seconds('source.occrtd', 'source.occrtt') }} as created_datetime,
    {{ julian_datetime_seconds('source.occhgd', 'source.occhgt') }} as changed_datetime
from {{ source('iesfilec', 'comment') }} as source
