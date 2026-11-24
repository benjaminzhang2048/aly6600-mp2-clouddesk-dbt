{% snapshot snp_subscriptions %}

{{
    config(
        target_schema='mp2',
        unique_key='subscription_id',
        strategy='check',
        check_cols=['plan', 'seats', 'mrr', 'status']
    )
}}

select
    cast(subscription_id as int64) as subscription_id,
    cast(account_id as int64) as account_id,
    trim(cast(plan as string)) as plan,
    cast(seats as int64) as seats,
    cast(mrr as numeric) as mrr,
    lower(trim(cast(status as string))) as status,
    cast(started_at as date) as started_at,
    cast(updated_at as timestamp) as updated_at
from {{ source('clouddesk_raw', 'subscriptions') }}

{% endsnapshot %}
