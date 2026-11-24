with source_subscriptions as (

    select *
    from {{ source('clouddesk_raw', 'subscriptions') }}

),

cleaned as (

    select
        cast(subscription_id as int64) as subscription_id,
        cast(account_id as int64) as account_id,
        trim(cast(plan as string)) as plan_name,
        cast(seats as int64) as seats,
        cast(mrr as numeric) as raw_mrr,
        case
            when cast(mrr as numeric) = 99999 then null
            else cast(mrr as numeric)
        end as mrr,
        cast(mrr as numeric) = 99999 as is_mrr_outlier,
        lower(trim(cast(status as string))) as subscription_status,
        cast(started_at as date) as started_date,
        cast(updated_at as timestamp) as updated_at
    from source_subscriptions

)

select * from cleaned
