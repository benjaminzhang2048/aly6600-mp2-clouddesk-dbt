with source_users as (

    select *
    from {{ source('clouddesk_raw', 'users') }}

),

cleaned as (

    select
        cast(user_id as int64) as user_id,
        cast(account_id as int64) as account_id,
        lower(trim(cast(email as string))) as email,
        lower(trim(cast(role as string))) as user_role,
        cast(created_at as date) as created_date,
        safe_cast(nullif(trim(cast(last_login as string)), '') as date) as last_login_date,
        cast(updated_at as timestamp) as updated_at
    from source_users

)

select * from cleaned
