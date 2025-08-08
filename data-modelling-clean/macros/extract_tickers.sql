{% macro extract_tickers(text_column) %}
    -- Extract ticker symbols using regex
    regexp_matches(
        {{ text_column }},
        '\$[A-Z]{1,5}',
        'g'
    )
{% endmacro %}

{% macro extract_ticker_symbol(text_column) %}
    -- Extract ticker from $TICKER format
    case 
        when array_length(regexp_matches({{ text_column }}, '\$[A-Z]{1,5}', 'g'), 1) > 0 
        then substring(regexp_matches({{ text_column }}, '\$[A-Z]{1,5}', 'g')[1] from 2) -- Remove $ symbol
        else null
    end
{% endmacro %}

{% macro count_ticker_mentions(text_column) %}
    -- Count ticker mentions
    array_length(regexp_matches({{ text_column }}, '\$[A-Z]{1,5}', 'g'), 1)
{% endmacro %} 