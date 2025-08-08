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

-- Create sentiment events with basic sentiment processing
sentiment_events as (
    select
        -- Event identification
        row_number() over (order by content_date) as event_id,
        content_date as event_timestamp,
        date_trunc('hour', content_date) as event_hour,
        date_trunc('day', content_date) as event_date,
        
        -- Content details
        id as content_id,
        source_type,
        content_id as original_content_id,
        title,
        content,
        author,
        platform,
        url,
        
        -- Basic sentiment metrics
        basic_sentiment,
        positive_keyword_count,
        negative_keyword_count,
        sentiment_keyword_density,
        engagement_score,
        engagement_category,
        
        -- Content metrics
        title_length,
        content_length,
        word_count,
        content_length_category,
        hours_since_content,
        
        -- Ticker information
        extracted_ticker,
        ticker_mention_count,
        is_valid_ticker,
        
        -- Time dimensions
        extract(hour from content_date) as hour_of_day,
        extract(dow from content_date) as day_of_week,
        extract(month from content_date) as month,
        extract(year from content_date) as year,
        
        -- Event classification based on basic sentiment
        case 
            when sentiment_keyword_density > 0.1 then 'high_impact'
            when sentiment_keyword_density > 0.05 then 'medium_impact'
            else 'low_impact'
        end as impact_level,
        
        case 
            when basic_sentiment = 'positive' and sentiment_keyword_density > 0.05 then 'bullish_signal'
            when basic_sentiment = 'negative' and sentiment_keyword_density > 0.05 then 'bearish_signal'
            else 'neutral_signal'
        end as signal_type,
        
        -- Engagement classification
        case 
            when engagement_score > 100 then 'viral'
            when engagement_score > 50 then 'popular'
            when engagement_score > 10 then 'moderate'
            else 'low_engagement'
        end as engagement_level
    from sentiment_data
),

-- Join with price data for correlation analysis
price_correlation as (
    select
        se.*,
        pd.symbol,
        pd.close_price,
        pd.price_change_pct,
        pd.price_momentum,
        pd.volume,
        pd.volume_analysis,
        pd.trading_session,
        pd.rolling_volatility_24h,
        pd.avg_volume_24h,
        pd.price_acceleration,
        
        -- Basic sentiment-price correlation
        case 
            when se.basic_sentiment = 'positive' and pd.price_change_pct > 0 then 'positive_correlation'
            when se.basic_sentiment = 'negative' and pd.price_change_pct < 0 then 'negative_correlation'
            when se.basic_sentiment = 'positive' and pd.price_change_pct < 0 then 'contrarian_signal'
            when se.basic_sentiment = 'negative' and pd.price_change_pct > 0 then 'contrarian_signal'
            else 'no_correlation'
        end as sentiment_price_correlation,
        
        -- Time lag analysis
        extract(epoch from (pd.date - se.event_timestamp)) / 3600 as hours_between_sentiment_price
        
    from sentiment_events se
    left join price_data pd 
        on se.event_hour = date_trunc('hour', pd.date)
        and pd.symbol = 'AAPL'  -- Focus on AAPL for now
)

select * from price_correlation 