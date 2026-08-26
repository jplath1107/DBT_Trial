{{ config(materialized='view') }}

{% set late_fees_billing_source = source('dbo', 'late_fees_billing') %}

select
    {{ select_columns_from_comments(late_fees_billing_source, 'source') }}
from {{ late_fees_billing_source }} as source
