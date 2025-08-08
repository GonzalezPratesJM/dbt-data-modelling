{{
  config(
    materialized='view'
  )
}}

with source as (
    select * from {{ source('raw_financial_data', 'reddit_posts') }}
),

renamed as (
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
        -- Add derived fields for sentiment processing
        case 
            when title is not null then length(title)
            else 0 
        end as title_length,
        case 
            when content is not null then length(content)
            else 0 
        end as content_length,
        -- Combine text for sentiment analysis
        coalesce(title, '') || ' ' || coalesce(content, '') as combined_text,
        -- Engagement metrics
        score + num_comments as total_engagement,
        case 
            when num_comments > 0 then score::float / num_comments
            else 0 
        end as score_per_comment,
        -- Extract date parts
        date_trunc('day', created_utc) as post_date,
        date_trunc('hour', created_utc) as post_hour,
        -- Time since post
        extract(epoch from (current_timestamp - created_utc)) / 3600 as hours_since_posted,
        -- Engagement categories
        case 
            when score > 100 then 'viral'
            when score > 50 then 'popular'
            when score > 10 then 'moderate'
            else 'low_engagement'
        end as engagement_category,
        -- Text preprocessing for sentiment analysis
        lower(coalesce(title, '') || ' ' || coalesce(content, '')) as normalized_text,
        -- Word count for analysis
        array_length(regexp_split_to_array(coalesce(title, '') || ' ' || coalesce(content, ''), '\s+'), 1) as word_count
    from source
)

select * from renamed 