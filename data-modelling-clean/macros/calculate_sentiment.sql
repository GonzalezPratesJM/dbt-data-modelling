{% macro calculate_sentiment_score(text_column, sentiment_keywords_table) %}
    -- Calculate sentiment score based on keyword matches
    sum(case when sk.sentiment = 'positive' then sk.weight else 0 end) as positive_score,
    sum(case when sk.sentiment = 'negative' then sk.weight else 0 end) as negative_score,
    sum(case when sk.sentiment = 'neutral' then sk.weight else 0 end) as neutral_score,
    -- Calculate overall sentiment
    case 
        when sum(case when sk.sentiment = 'positive' then sk.weight else 0 end) > 
             sum(case when sk.sentiment = 'negative' then sk.weight else 0 end)
        then 'positive'
        when sum(case when sk.sentiment = 'negative' then sk.weight else 0 end) > 
             sum(case when sk.sentiment = 'positive' then sk.weight else 0 end)
        then 'negative'
        else 'neutral'
    end as overall_sentiment,
    -- Calculate sentiment intensity
    abs(sum(case when sk.sentiment = 'positive' then sk.weight else 0 end) - 
        sum(case when sk.sentiment = 'negative' then sk.weight else 0 end)) as sentiment_intensity
{% endmacro %}

{% macro sentiment_classification(sentiment_intensity, overall_sentiment) %}
    case 
        when {{ sentiment_intensity }} > 5 and {{ overall_sentiment }} = 'positive' then 'strong_positive'
        when {{ sentiment_intensity }} > 3 and {{ overall_sentiment }} = 'positive' then 'moderate_positive'
        when {{ sentiment_intensity }} > 5 and {{ overall_sentiment }} = 'negative' then 'strong_negative'
        when {{ sentiment_intensity }} > 3 and {{ overall_sentiment }} = 'negative' then 'moderate_negative'
        else 'neutral'
    end
{% endmacro %} 

{% macro calculate_basic_sentiment(text_column) %}
    -- Basic keyword-based sentiment calculation
    case 
        when {{ text_column }} like '%bullish%' or {{ text_column }} like '%bull%' then 'positive'
        when {{ text_column }} like '%bearish%' or {{ text_column }} like '%bear%' then 'negative'
        when {{ text_column }} like '%surge%' or {{ text_column }} like '%rally%' then 'positive'
        when {{ text_column }} like '%crash%' or {{ text_column }} like '%plunge%' then 'negative'
        when {{ text_column }} like '%gain%' or {{ text_column }} like '%rise%' then 'positive'
        when {{ text_column }} like '%drop%' or {{ text_column }} like '%fall%' then 'negative'
        else 'neutral'
    end
{% endmacro %}

{% macro count_positive_keywords(text_column) %}
    -- Count positive keywords
    array_length(regexp_matches({{ text_column }}, 'bullish|bull|surge|rally|gain|rise|positive|strong|growth|profit|beat|exceed|buy', 'g'), 1)
{% endmacro %}

{% macro count_negative_keywords(text_column) %}
    -- Count negative keywords
    array_length(regexp_matches({{ text_column }}, 'bearish|bear|crash|plunge|drop|fall|negative|weak|loss|decline|miss|sell', 'g'), 1)
{% endmacro %}

{% macro calculate_sentiment_density(text_column, word_count_column) %}
    -- Calculate sentiment keyword density
    case 
        when {{ word_count_column }} > 0 then 
            (array_length(regexp_matches({{ text_column }}, 'bullish|bull|surge|rally|gain|rise|positive|strong|growth|profit|beat|exceed|buy', 'g'), 1) + 
             array_length(regexp_matches({{ text_column }}, 'bearish|bear|crash|plunge|drop|fall|negative|weak|loss|decline|miss|sell', 'g'), 1))::float / {{ word_count_column }}
        else 0
    end
{% endmacro %} 