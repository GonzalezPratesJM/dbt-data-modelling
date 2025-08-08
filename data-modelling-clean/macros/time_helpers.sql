{% macro is_market_hours(timestamp_column) %}
    case 
        when extract(hour from {{ timestamp_column }}) between 9 and 16 
        and extract(dow from {{ timestamp_column }}) between 1 and 5 
        then true 
        else false 
    end
{% endmacro %}

{% macro trading_session(hour_column) %}
    case 
        when {{ hour_column }} between 9 and 11 then 'morning_session'
        when {{ hour_column }} between 12 and 15 then 'midday_session'
        when {{ hour_column }} between 16 and 20 then 'afternoon_session'
        else 'extended_hours'
    end
{% endmacro %}

{% macro hours_since_event(event_timestamp) %}
    extract(epoch from (current_timestamp - {{ event_timestamp }})) / 3600
{% endmacro %}

{% macro rolling_average(column_name, partition_by, order_by, window_size) %}
    avg({{ column_name }}) over (
        partition by {{ partition_by }} 
        order by {{ order_by }} 
        rows between {{ window_size - 1 }} preceding and current row
    )
{% endmacro %}

{% macro rolling_volatility(column_name, partition_by, order_by, window_size) %}
    stddev({{ column_name }}) over (
        partition by {{ partition_by }} 
        order by {{ order_by }} 
        rows between {{ window_size - 1 }} preceding and current row
    )
{% endmacro %} 