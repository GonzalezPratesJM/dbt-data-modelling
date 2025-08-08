{{
  config(
    materialized='table'
  )
}}

with ml_features as (
    select * from {{ ref('mart_ml_features') }}
),

sentiment_events as (
    select * from {{ ref('fact_sentiment_events') }}
),

-- Create agent-ready data with basic sentiment signals
agent_signals as (
    select
        feature_timestamp,
        analysis_date,
        hour_of_day,
        day_of_week,
        
        -- Current market state
        avg_price_change_pct as current_price_change,
        avg_sentiment_density as current_sentiment_density,
        total_content_count as current_content_volume,
        positive_sentiment_ratio as current_bullish_ratio,
        negative_sentiment_ratio as current_bearish_ratio,
        
        -- Predictive signals
        target_price_change_next_hour as predicted_price_change,
        target_price_direction as predicted_direction,
        
        -- Trend indicators
        price_change_prev_hour as previous_price_change,
        sentiment_density_prev_hour as previous_sentiment_density,
        price_change_6h_avg as price_trend_6h,
        sentiment_density_6h_avg as sentiment_trend_6h,
        
        -- Volatility indicators
        price_volatility_24h,
        sentiment_volatility_24h,
        
        -- Market conditions
        is_market_hours,
        is_weekday,
        sentiment_category,
        price_momentum_category,
        
        -- Interaction signals
        sentiment_price_interaction,
        volume_sentiment_interaction,
        sentiment_price_ratio,
        sentiment_per_content_ratio,
        
        -- Normalized features for ML
        normalized_price_change,
        normalized_sentiment_density,
        
        -- Agent action recommendations based on basic sentiment
        case 
            when predicted_direction = 'up' and avg_sentiment_density > 0.05 
            then 'strong_buy_signal'
            when predicted_direction = 'down' and avg_sentiment_density > 0.05 
            then 'strong_sell_signal'
            when predicted_direction = 'up' and avg_sentiment_density > 0.02 
            then 'moderate_buy_signal'
            when predicted_direction = 'down' and avg_sentiment_density > 0.02 
            then 'moderate_sell_signal'
            else 'hold_signal'
        end as trading_signal,
        
        case 
            when positive_count > negative_count and avg_price_change_pct > 0 
            then 'bullish_momentum'
            when negative_count > positive_count and avg_price_change_pct < 0 
            then 'bearish_momentum'
            when positive_count > negative_count and avg_price_change_pct < 0 
            then 'bullish_divergence'
            when negative_count > positive_count and avg_price_change_pct > 0 
            then 'bearish_divergence'
            else 'neutral_momentum'
        end as momentum_signal,
        
        -- Risk assessment
        case 
            when price_volatility_24h > 5 then 'high_volatility'
            when price_volatility_24h > 2 then 'medium_volatility'
            else 'low_volatility'
        end as volatility_risk,
        
        case 
            when sentiment_volatility_24h > 0.1 then 'high_sentiment_volatility'
            when sentiment_volatility_24h > 0.05 then 'medium_sentiment_volatility'
            else 'low_sentiment_volatility'
        end as sentiment_risk,
        
        -- Confidence scores based on basic sentiment
        case 
            when abs(predicted_price_change) > 2 then 0.9
            when abs(predicted_price_change) > 1 then 0.7
            when abs(predicted_price_change) > 0.5 then 0.5
            else 0.3
        end as prediction_confidence,
        
        case 
            when avg_sentiment_density > 0.1 then 0.9
            when avg_sentiment_density > 0.05 then 0.7
            when avg_sentiment_density > 0.02 then 0.5
            else 0.3
        end as sentiment_confidence,
        
        -- Timestamp for real-time processing
        current_timestamp as processed_at
        
    from ml_features
),

-- Add recent sentiment events for context
recent_events as (
    select
        as.*,
        -- Recent high-impact events
        count(case when se.impact_level = 'high_impact' and se.event_timestamp >= as.feature_timestamp - interval '1 hour' then 1 end) as high_impact_events_1h,
        count(case when se.signal_type = 'bullish_signal' and se.event_timestamp >= as.feature_timestamp - interval '1 hour' then 1 end) as bullish_signals_1h,
        count(case when se.signal_type = 'bearish_signal' and se.event_timestamp >= as.feature_timestamp - interval '1 hour' then 1 end) as bearish_signals_1h,
        
        -- Recent viral content
        count(case when se.engagement_level = 'viral' and se.event_timestamp >= as.feature_timestamp - interval '1 hour' then 1 end) as viral_content_1h,
        
        -- Source breakdown
        count(case when se.source_type = 'news' and se.event_timestamp >= as.feature_timestamp - interval '1 hour' then 1 end) as news_events_1h,
        count(case when se.source_type = 'reddit' and se.event_timestamp >= as.feature_timestamp - interval '1 hour' then 1 end) as reddit_events_1h
        
    from agent_signals as
    left join sentiment_events se 
        on se.event_timestamp >= as.feature_timestamp - interval '1 hour'
        and se.event_timestamp < as.feature_timestamp
    group by 
        as.feature_timestamp, as.analysis_date, as.hour_of_day, as.day_of_week,
        as.current_price_change, as.current_sentiment_density, as.current_content_volume,
        as.current_bullish_ratio, as.current_bearish_ratio, as.predicted_price_change,
        as.predicted_direction, as.previous_price_change, as.previous_sentiment_density,
        as.price_trend_6h, as.sentiment_trend_6h, as.price_volatility_24h, as.sentiment_volatility_24h,
        as.is_market_hours, as.is_weekday, as.sentiment_category, as.price_momentum_category,
        as.sentiment_price_interaction, as.volume_sentiment_interaction, as.sentiment_price_ratio,
        as.sentiment_per_content_ratio, as.normalized_price_change, as.normalized_sentiment_density,
        as.trading_signal, as.momentum_signal, as.volatility_risk, as.sentiment_risk,
        as.prediction_confidence, as.sentiment_confidence, as.processed_at
)

select * from recent_events 