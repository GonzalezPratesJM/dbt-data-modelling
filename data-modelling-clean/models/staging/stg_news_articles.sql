{{
  config(
    materialized='view'
  )
}}

with source as (
    select * from {{ source('raw_financial_data', 'news_articles') }}
),

renamed as (
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
        coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(content, '') as combined_text,
        -- Extract date parts
        date_trunc('day', published_at) as published_date,
        date_trunc('hour', published_at) as published_hour,
        -- Time since publication
        extract(epoch from (current_timestamp - published_at)) / 3600 as hours_since_published,
        -- Text preprocessing for sentiment analysis
        lower(coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(content, '')) as normalized_text,
        -- Word count for analysis
        array_length(regexp_split_to_array(coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(content, ''), '\s+'), 1) as word_count
    from source
)

select * from renamed 