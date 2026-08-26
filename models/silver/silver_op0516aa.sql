{{ config(materialized='view', alias='advance_records') }}

select
    source.*,
    {{ julian_datetime('source.sa09a', 'source.sa10a') }} as advance_datetime
from {{ source('cccfilec', 'op0516aa') }} as source
