{{
  config(
    materialized='table'
  )
}}

with time_windows as (
    select * from {{ ref('int_time_windows') }}
),

sentiment_events as (
    select * from {{ ref('fact_sentiment_events') }}
),

-- Create ML-ready features with basic sentiment
ml_features as (
    select
        tw.analysis_hour as feature_timestamp,
        tw.analysis_date,
        tw.hour_of_day,
        tw.day_of_week,
        
        -- Target variable (price movement in next hour)
        lead(tw.avg_price_change_pct, 1) over (
            partition by tw.symbol 
            order by tw.analysis_hour
        ) as target_price_change_next_hour,
        
        -- Basic sentiment features
        tw.total_content_count,
        tw.positive_count,
        tw.negative_count,
        tw.neutral_count,
        tw.avg_positive_keywords,
        tw.avg_negative_keywords,
        tw.avg_sentiment_density,
        tw.positive_sentiment_ratio,
        tw.negative_sentiment_ratio,
        tw.sentiment_price_correlation,
        
        -- Content features
        tw.avg_title_length,
        tw.avg_content_length,
        tw.avg_word_count,
        tw.ticker_mention_count,
        tw.valid_ticker_count,
        
        -- Price features
        tw.avg_close_price,
        tw.max_high_price,
        tw.min_low_price,
        tw.total_volume,
        tw.avg_price_change_pct,
        tw.max_price_change_pct,
        tw.min_price_change_pct,
        tw.avg_volatility,
        
        -- Momentum features
        tw.strong_up_count,
        tw.moderate_up_count,
        tw.stable_count,
        tw.moderate_down_count,
        tw.strong_down_count,
        
        -- Engagement features
        tw.avg_engagement_score,
        tw.news_count,
        tw.reddit_count,
        
        -- Lagged features (previous hour)
        lag(tw.avg_price_change_pct, 1) over (
            partition by tw.symbol 
            order by tw.analysis_hour
        ) as price_change_prev_hour,
        lag(tw.avg_sentiment_density, 1) over (
            partition by tw.symbol 
            order by tw.analysis_hour
        ) as sentiment_density_prev_hour,
        lag(tw.total_content_count, 1) over (
            partition by tw.symbol 
            order by tw.analysis_hour
        ) as content_count_prev_hour,
        
        -- Rolling averages (last 6 hours)
        avg(tw.avg_price_change_pct) over (
            partition by tw.symbol 
            order by tw.analysis_hour 
            rows between 5 preceding and current row
        ) as price_change_6h_avg,
        avg(tw.avg_sentiment_density) over (
            partition by tw.symbol 
            order by tw.analysis_hour 
            rows between 5 preceding and current row
        ) as sentiment_density_6h_avg,
        avg(tw.total_content_count) over (
            partition by tw.symbol 
            order by tw.analysis_hour 
            rows between 5 preceding and current row
        ) as content_count_6h_avg,
        
        -- Volatility features
        stddev(tw.avg_price_change_pct) over (
            partition by tw.symbol 
            order by tw.analysis_hour 
            rows between 23 preceding and current row
        ) as price_volatility_24h,
        stddev(tw.avg_sentiment_density) over (
            partition by tw.symbol 
            order by tw.analysis_hour 
            rows between 23 preceding and current row
        ) as sentiment_volatility_24h,
        
        -- Time-based features
        case when tw.hour_of_day between 9 and 16 then 1 else 0 end as is_market_hours,
        case when tw.day_of_week between 1 and 5 then 1 else 0 end as is_weekday,
        
        -- Interaction features
        tw.avg_sentiment_density * tw.avg_price_change_pct as sentiment_price_interaction,
        tw.total_content_count * tw.avg_sentiment_density as volume_sentiment_interaction,
        
        -- Categorical features
        case 
            when tw.positive_count > tw.negative_count and tw.positive_count > tw.neutral_count then 'high_positive'
            when tw.positive_count > tw.negative_count then 'moderate_positive'
            when tw.negative_count > tw.positive_count and tw.negative_count > tw.neutral_count then 'high_negative'
            when tw.negative_count > tw.positive_count then 'moderate_negative'
            else 'neutral'
        end as sentiment_category,
        
        case 
            when tw.avg_price_change_pct > 2 then 'strong_up'
            when tw.avg_price_change_pct > 0.5 then 'moderate_up'
            when tw.avg_price_change_pct > -0.5 then 'stable'
            when tw.avg_price_change_pct > -2 then 'moderate_down'
            else 'strong_down'
        end as price_momentum_category
        
    from time_windows tw
    where tw.symbol = 'AAPL'  -- Focus on AAPL
),

-- Add derived features
final_features as (
    select
        *,
        -- Target classification
        case 
            when target_price_change_next_hour > 0.5 then 'up'
            when target_price_change_next_hour < -0.5 then 'down'
            else 'stable'
        end as target_price_direction,
        
        -- Feature ratios
        case 
            when avg_price_change_pct != 0 
            then avg_sentiment_density / abs(avg_price_change_pct)
            else 0 
        end as sentiment_price_ratio,
        
        case 
            when total_content_count > 0 
            then avg_sentiment_density / total_content_count
            else 0 
        end as sentiment_per_content_ratio,
        
        -- Normalized features
        (avg_price_change_pct - avg(avg_price_change_pct) over ()) / 
        nullif(stddev(avg_price_change_pct) over (), 0) as normalized_price_change,
        
        (avg_sentiment_density - avg(avg_sentiment_density) over ()) / 
        nullif(stddev(avg_sentiment_density) over (), 0) as normalized_sentiment_density
        
    from ml_features
)

select * from final_features 