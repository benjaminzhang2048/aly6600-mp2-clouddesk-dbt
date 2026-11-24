with source_tickets as (

    select *
    from {{ source('clouddesk_raw', 'tickets') }}

),

cleaned as (

    select
        cast(ticket_id as int64) as ticket_id,
        cast(account_id as int64) as account_id,
        cast(opened_at as timestamp) as opened_at,
        safe_cast(nullif(trim(cast(closed_at as string)), '') as timestamp) as closed_at,
        lower(trim(cast(priority as string))) as priority,
        trim(cast(category as string)) as category,
        lower(trim(cast(status as string))) as ticket_status,
        cast(updated_at as timestamp) as updated_at
    from source_tickets

)

select * from cleaned
