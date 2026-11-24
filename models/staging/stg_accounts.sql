with source_accounts as (

    select *
    from {{ source('clouddesk_raw', 'accounts') }}

),

cleaned as (

    select
        cast(account_id as int64) as account_id,
        trim(cast(company_name as string)) as company_name,
        nullif(trim(cast(industry as string)), '') as industry,
        upper(trim(cast(region as string))) as region,
        cast(signup_date as date) as signup_date,
        cast(updated_at as timestamp) as updated_at
    from source_accounts

)

select * from cleaned
