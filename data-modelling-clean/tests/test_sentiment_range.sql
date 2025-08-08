-- Test to ensure basic sentiment scores are within expected ranges

{% test test_basic_sentiment_range(model, positive_keyword_count_column, negative_keyword_count_column, sentiment_density_column) %}

with sentiment_validation as (
    select
        {{ positive_keyword_count_column }},
        {{ negative_keyword_count_column }},
        {{ sentiment_density_column }}
    from {{ model }}
    where 
        {{ positive_keyword_count_column }} < 0 
        or {{ negative_keyword_count_column }} < 0 
        or {{ sentiment_density_column }} < 0
        or {{ positive_keyword_count_column }} > 100
        or {{ negative_keyword_count_column }} > 100
        or {{ sentiment_density_column }} > 1
)

select *
from sentiment_validation

{% endtest %} 