{{
  config(
    materialized='table'
  )
}}

with stock_symbols as (
    select * from {{ ref('stock_symbols') }}
),

-- Get latest stock data for each symbol
latest_stock_data as (
    select
        symbol,
        max(date) as latest_price_date,
        max(close_price) as latest_close_price,
        avg(close_price) as avg_close_price_30d,
        sum(volume) as total_volume_30d,
        avg(price_change_pct) as avg_price_change_30d,
        stddev(price_change_pct) as price_volatility_30d
    from {{ ref('stg_stock_prices') }}
    where date >= current_date - interval '30 days'
    group by symbol
),

-- Get basic sentiment data for each symbol
basic_sentiment_summary as (
    select
        extracted_ticker as symbol,
        count(*) as total_mentions,
        count(case when basic_sentiment = 'positive' then 1 end) as positive_mentions,
        count(case when basic_sentiment = 'negative' then 1 end) as negative_mentions,
        count(case when basic_sentiment = 'neutral' then 1 end) as neutral_mentions,
        avg(positive_keyword_count) as avg_positive_keywords,
        avg(negative_keyword_count) as avg_negative_keywords,
        avg(sentiment_keyword_density) as avg_sentiment_density
    from {{ ref('int_ticker_extraction') }}
    where extracted_ticker is not null and is_valid_ticker = true
    group by extracted_ticker
)

-- Combine stock and basic sentiment data
select
    coalesce(ss.symbol, lsd.symbol) as symbol,
    ss.company_name,
    ss.sector,
    lsd.latest_price_date,
    lsd.latest_close_price,
    lsd.avg_close_price_30d,
    lsd.total_volume_30d,
    lsd.avg_price_change_30d,
    lsd.price_volatility_30d,
    coalesce(sent.total_mentions, 0) as total_mentions,
    coalesce(sent.positive_mentions, 0) as positive_mentions,
    coalesce(sent.negative_mentions, 0) as negative_mentions,
    coalesce(sent.neutral_mentions, 0) as neutral_mentions,
    sent.avg_positive_keywords,
    sent.avg_negative_keywords,
    sent.avg_sentiment_density,
    -- Calculate basic sentiment ratios
    case 
        when sent.total_mentions > 0 
        then sent.positive_mentions::float / sent.total_mentions 
        else 0 
    end as positive_sentiment_ratio,
    case 
        when sent.total_mentions > 0 
        then sent.negative_mentions::float / sent.total_mentions 
        else 0 
    end as negative_sentiment_ratio,
    -- Basic sentiment classification
    case 
        when sent.positive_mentions > sent.negative_mentions and sent.positive_mentions > sent.neutral_mentions then 'bullish'
        when sent.negative_mentions > sent.positive_mentions and sent.negative_mentions > sent.neutral_mentions then 'bearish'
        else 'neutral'
    end as basic_sentiment_classification,
    -- Market performance classification
    case 
        when lsd.avg_price_change_30d > 5 then 'strong_performer'
        when lsd.avg_price_change_30d > 0 then 'moderate_performer'
        when lsd.avg_price_change_30d > -5 then 'underperformer'
        else 'poor_performer'
    end as performance_classification,
    current_timestamp as last_updated
from stock_symbols ss
full outer join latest_stock_data lsd on ss.symbol = lsd.symbol
full outer join basic_sentiment_summary sent on coalesce(ss.symbol, lsd.symbol) = sent.symbol 