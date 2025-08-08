{{
  config(
    materialized='table'
  )
}}

with news_articles as (
    select * from {{ ref('stg_news_articles') }}
),

reddit_posts as (
    select * from {{ ref('stg_reddit_posts') }}
),

-- Basic sentiment processing for news articles
news_basic_sentiment as (
    select
        id,
        article_id,
        title,
        description,
        content,
        author,
        source_name,
        url,
        published_at,
        collected_at,
        title_length,
        content_length,
        combined_text,
        normalized_text,
        word_count,
        published_date,
        published_hour,
        hours_since_published,
        -- Basic text features for sentiment analysis
        case 
            when word_count > 100 then 'long_content'
            when word_count > 50 then 'medium_content'
            else 'short_content'
        end as content_length_category,
        -- Simple keyword-based sentiment (basic approach)
        case 
            when normalized_text like '%bullish%' or normalized_text like '%bull%' then 'positive'
            when normalized_text like '%bearish%' or normalized_text like '%bear%' then 'negative'
            when normalized_text like '%surge%' or normalized_text like '%rally%' then 'positive'
            when normalized_text like '%crash%' or normalized_text like '%plunge%' then 'negative'
            when normalized_text like '%gain%' or normalized_text like '%rise%' then 'positive'
            when normalized_text like '%drop%' or normalized_text like '%fall%' then 'negative'
            else 'neutral'
        end as basic_sentiment,
        -- Count positive/negative keywords
        array_length(regexp_matches(normalized_text, 'bullish|bull|surge|rally|gain|rise|positive|strong|growth|profit|beat|exceed|buy', 'g'), 1) as positive_keyword_count,
        array_length(regexp_matches(normalized_text, 'bearish|bear|crash|plunge|drop|fall|negative|weak|loss|decline|miss|sell', 'g'), 1) as negative_keyword_count,
        -- Sentiment intensity based on keyword density
        case 
            when word_count > 0 then 
                (array_length(regexp_matches(normalized_text, 'bullish|bull|surge|rally|gain|rise|positive|strong|growth|profit|beat|exceed|buy', 'g'), 1) + 
                 array_length(regexp_matches(normalized_text, 'bearish|bear|crash|plunge|drop|fall|negative|weak|loss|decline|miss|sell', 'g'), 1))::float / word_count
            else 0
        end as sentiment_keyword_density
    from news_articles
),

-- Basic sentiment processing for Reddit posts
reddit_basic_sentiment as (
    select
        id,
        post_id,
        title,
        content,
        author,
        score,
        num_comments,
        created_utc,
        subreddit,
        url,
        collected_at,
        title_length,
        content_length,
        combined_text,
        normalized_text,
        word_count,
        total_engagement,
        score_per_comment,
        post_date,
        post_hour,
        hours_since_posted,
        engagement_category,
        -- Basic text features for sentiment analysis
        case 
            when word_count > 100 then 'long_content'
            when word_count > 50 then 'medium_content'
            else 'short_content'
        end as content_length_category,
        -- Simple keyword-based sentiment (basic approach)
        case 
            when normalized_text like '%bullish%' or normalized_text like '%bull%' then 'positive'
            when normalized_text like '%bearish%' or normalized_text like '%bear%' then 'negative'
            when normalized_text like '%surge%' or normalized_text like '%rally%' then 'positive'
            when normalized_text like '%crash%' or normalized_text like '%plunge%' then 'negative'
            when normalized_text like '%gain%' or normalized_text like '%rise%' then 'positive'
            when normalized_text like '%drop%' or normalized_text like '%fall%' then 'negative'
            else 'neutral'
        end as basic_sentiment,
        -- Count positive/negative keywords
        array_length(regexp_matches(normalized_text, 'bullish|bull|surge|rally|gain|rise|positive|strong|growth|profit|beat|exceed|buy', 'g'), 1) as positive_keyword_count,
        array_length(regexp_matches(normalized_text, 'bearish|bear|crash|plunge|drop|fall|negative|weak|loss|decline|miss|sell', 'g'), 1) as negative_keyword_count,
        -- Sentiment intensity based on keyword density
        case 
            when word_count > 0 then 
                (array_length(regexp_matches(normalized_text, 'bullish|bull|surge|rally|gain|rise|positive|strong|growth|profit|beat|exceed|buy', 'g'), 1) + 
                 array_length(regexp_matches(normalized_text, 'bearish|bear|crash|plunge|drop|fall|negative|weak|loss|decline|miss|sell', 'g'), 1))::float / word_count
            else 0
        end as sentiment_keyword_density
    from reddit_posts
)

-- Combine news and Reddit basic sentiment
select 
    'news' as source_type,
    id,
    article_id as content_id,
    title,
    description as content,
    author,
    source_name as platform,
    url,
    published_at as content_date,
    collected_at,
    title_length,
    content_length,
    word_count,
    content_length_category,
    basic_sentiment,
    positive_keyword_count,
    negative_keyword_count,
    sentiment_keyword_density,
    published_date,
    published_hour,
    hours_since_published,
    null as engagement_score,
    null as engagement_category
from news_basic_sentiment

union all

select 
    'reddit' as source_type,
    id,
    post_id as content_id,
    title,
    content,
    author,
    subreddit as platform,
    url,
    created_utc as content_date,
    collected_at,
    title_length,
    content_length,
    word_count,
    content_length_category,
    basic_sentiment,
    positive_keyword_count,
    negative_keyword_count,
    sentiment_keyword_density,
    post_date as published_date,
    post_hour as published_hour,
    hours_since_posted as hours_since_published,
    total_engagement as engagement_score,
    engagement_category
from reddit_basic_sentiment 