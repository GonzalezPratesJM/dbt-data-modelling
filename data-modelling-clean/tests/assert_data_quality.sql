-- Generic test for data quality
-- This test can be applied to any model to check for common data quality issues

{% test assert_data_quality(model, column_name) %}

with validation_errors as (
    select
        {{ column_name }},
        count(*) as count_records
    from {{ model }}
    where {{ column_name }} is null
    group by {{ column_name }}
    having count(*) > 0
)

select *
from validation_errors

{% endtest %} 