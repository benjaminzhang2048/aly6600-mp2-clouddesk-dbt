{{ config(materialized='table') }}

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
    is_sla_met,
    account_region,
    has_active_subscription
from {{ ref('int_tickets_enriched') }}
