{{
  config(
    materialized='table'
  )
}}

with sentiment_data as (
    select * from {{ ref('int_ticker_extraction') }}
),

price_data as (
    select * from {{ ref('int_price_movements') }}
),

-- Create time windows for analysis
time_windows as (
    select
        date_trunc('hour', content_date) as analysis_hour,
        date_trunc('day', content_date) as analysis_date,
        extract(hour from content_date) as hour_of_day,
        extract(dow from content_date) as day_of_week,
        -- Basic sentiment aggregation
        count(*) as total_content_count,
        count(case when basic_sentiment = 'positive' then 1 end) as positive_count,
        count(case when basic_sentiment = 'negative' then 1 end) as negative_count,
        count(case when basic_sentiment = 'neutral' then 1 end) as neutral_count,
        -- Basic sentiment scores
        avg(positive_keyword_count) as avg_positive_keywords,
        avg(negative_keyword_count) as avg_negative_keywords,
        avg(sentiment_keyword_density) as avg_sentiment_density,
        -- Engagement metrics
        avg(engagement_score) as avg_engagement_score,
        -- Source breakdown
        count(case when source_type = 'news' then 1 end) as news_count,
        count(case when source_type = 'reddit' then 1 end) as reddit_count,
        -- Content metrics
        avg(title_length) as avg_title_length,
        avg(content_length) as avg_content_length,
        avg(word_count) as avg_word_count,
        -- Ticker mentions
        count(case when extracted_ticker is not null then 1 end) as ticker_mention_count,
        count(case when is_valid_ticker = true then 1 end) as valid_ticker_count
    from sentiment_data
    group by 
        date_trunc('hour', content_date),
        date_trunc('day', content_date),
        extract(hour from content_date),
        extract(dow from content_date)
),

-- Price data aggregation by time windows
price_windows as (
    select
        date_trunc('hour', date) as analysis_hour,
        date_trunc('day', date) as analysis_date,
        extract(hour from date) as hour_of_day,
        extract(dow from date) as day_of_week,
        symbol,
        -- Price metrics
        avg(close_price) as avg_close_price,
        max(high_price) as max_high_price,
        min(low_price) as min_low_price,
        sum(volume) as total_volume,
        -- Price changes
        avg(price_change_pct) as avg_price_change_pct,
        max(price_change_pct) as max_price_change_pct,
        min(price_change_pct) as min_price_change_pct,
        -- Volatility
        avg(rolling_volatility_24h) as avg_volatility,
        -- Momentum
        count(case when price_momentum = 'strong_up' then 1 end) as strong_up_count,
        count(case when price_momentum = 'moderate_up' then 1 end) as moderate_up_count,
        count(case when price_momentum = 'stable' then 1 end) as stable_count,
        count(case when price_momentum = 'moderate_down' then 1 end) as moderate_down_count,
        count(case when price_momentum = 'strong_down' then 1 end) as strong_down_count
    from price_data
    group by 
        date_trunc('hour', date),
        date_trunc('day', date),
        extract(hour from date),
        extract(dow from date),
        symbol
)

-- Combine sentiment and price data by time windows
select
    tw.analysis_hour,
    tw.analysis_date,
    tw.hour_of_day,
    tw.day_of_week,
    -- Basic sentiment metrics
    tw.total_content_count,
    tw.positive_count,
    tw.negative_count,
    tw.neutral_count,
    tw.avg_positive_keywords,
    tw.avg_negative_keywords,
    tw.avg_sentiment_density,
    tw.avg_engagement_score,
    tw.news_count,
    tw.reddit_count,
    tw.avg_title_length,
    tw.avg_content_length,
    tw.avg_word_count,
    tw.ticker_mention_count,
    tw.valid_ticker_count,
    -- Price metrics (for AAPL)
    pw.symbol,
    pw.avg_close_price,
    pw.max_high_price,
    pw.min_low_price,
    pw.total_volume,
    pw.avg_price_change_pct,
    pw.max_price_change_pct,
    pw.min_price_change_pct,
    pw.avg_volatility,
    pw.strong_up_count,
    pw.moderate_up_count,
    pw.stable_count,
    pw.moderate_down_count,
    pw.strong_down_count,
    -- Basic sentiment ratios
    case 
        when tw.total_content_count > 0 
        then tw.positive_count::float / tw.total_content_count 
        else 0 
    end as positive_sentiment_ratio,
    case 
        when tw.total_content_count > 0 
        then tw.negative_count::float / tw.total_content_count 
        else 0 
    end as negative_sentiment_ratio,
    -- Basic sentiment vs price correlation indicators
    case 
        when pw.avg_price_change_pct > 0 and tw.positive_count > tw.negative_count 
        then 'positive_correlation'
        when pw.avg_price_change_pct < 0 and tw.negative_count > tw.positive_count 
        then 'negative_correlation'
        else 'no_correlation'
    end as sentiment_price_correlation
from time_windows tw
left join price_windows pw 
    on tw.analysis_hour = pw.analysis_hour 
    and pw.symbol = 'AAPL'  -- Focus on AAPL for now 