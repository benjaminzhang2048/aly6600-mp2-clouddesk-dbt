with tickets as (

    select *
    from {{ ref('stg_tickets') }}

),

accounts as (

    select
        account_id,
        region,
        has_active_subscription
    from {{ ref('int_account_rollup') }}

),

enriched as (

    select
        t.ticket_id,
        t.account_id,
        t.opened_at,
        date(t.opened_at) as opened_date,
        t.closed_at,
        t.priority,
        t.category,
        t.ticket_status,
        t.ticket_status = 'open' as is_open,
        case
            when t.closed_at is not null
                then round(timestamp_diff(t.closed_at, t.opened_at, minute) / 60.0, 2)
            else null
        end as resolution_hours,
        case t.priority
            when 'urgent' then 4
            when 'high' then 24
            when 'medium' then 48
            else 72
        end as sla_target_hours,
        a.region as account_region,
        a.has_active_subscription
    from tickets as t
    left join accounts as a
        on t.account_id = a.account_id

)

select
    ticket_id,
    account_id,
    opened_at,
    opened_date,
    closed_at,
    priority,
    category,
    ticket_status,
    is_open,
    resolution_hours,
    sla_target_hours,
    case
        when resolution_hours is not null then resolution_hours <= sla_target_hours
        else null
    end as is_sla_met,
    account_region,
    has_active_subscription
from enriched
