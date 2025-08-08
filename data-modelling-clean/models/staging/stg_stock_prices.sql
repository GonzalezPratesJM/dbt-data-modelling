{{
  config(
    materialized='view'
  )
}}

with source as (
    select * from {{ source('raw_financial_data', 'stock_prices') }}
),

renamed as (
    select
        id,
        symbol,
        date,
        open_price,
        high_price,
        low_price,
        close_price,
        volume,
        collected_at,
        -- Calculate price changes
        close_price - open_price as price_change,
        ((close_price - open_price) / open_price) * 100 as price_change_pct,
        high_price - low_price as daily_range,
        ((high_price - low_price) / open_price) * 100 as daily_range_pct,
        -- Calculate moving averages (if we have enough data)
        avg(close_price) over (
            partition by symbol 
            order by date 
            rows between 23 preceding and current row
        ) as ma_24h,
        avg(close_price) over (
            partition by symbol 
            order by date 
            rows between 167 preceding and current row
        ) as ma_168h, -- 7 days
        -- Extract date parts
        date_trunc('day', date) as trade_date,
        date_trunc('hour', date) as trade_hour,
        extract(hour from date) as hour_of_day,
        extract(dow from date) as day_of_week,
        -- Volume analysis
        case 
            when volume > avg(volume) over (partition by symbol order by date rows between 23 preceding and current row)
            then 'high_volume'
            else 'normal_volume'
        end as volume_category
    from source
)

select * from renamed 