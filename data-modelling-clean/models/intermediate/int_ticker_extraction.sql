{{
  config(
    materialized='table'
  )
}}

with basic_sentiment as (
    select * from {{ ref('int_basic_sentiment') }}
),

-- Extract ticker symbols from content
ticker_extraction as (
    select
        *,
        -- Extract ticker symbols using regex
        regexp_matches(
            combined_text,
            '\$[A-Z]{1,5}',
            'g'
        ) as ticker_matches,
        -- Also look for tickers without $ symbol (common stock symbols)
        regexp_matches(
            combined_text,
            '\b[A-Z]{1,5}\b',
            'g'
        ) as potential_tickers
    from basic_sentiment
),

-- Flatten and process ticker matches
processed_tickers as (
    select
        *,
        -- Extract ticker from $TICKER format
        case 
            when array_length(ticker_matches, 1) > 0 
            then substring(ticker_matches[1] from 2) -- Remove $ symbol
            else null
        end as extracted_ticker,
        -- Count mentions
        array_length(ticker_matches, 1) as ticker_mention_count,
        -- Validate ticker against known stock symbols
        case 
            when array_length(ticker_matches, 1) > 0 
            then substring(ticker_matches[1] from 2) in ('AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'META', 'NVDA', 'NFLX', 'JPM', 'JNJ', 'V', 'PG', 'HD', 'MA', 'UNH', 'DIS', 'PYPL', 'ADBE', 'CRM', 'NKE')
            else false
        end as is_valid_ticker
    from ticker_extraction
)

select * from processed_tickers 