-- Custom SQL Business Rule Test: Ticket Resolution Timeline Consistency
--
-- Why it matters for CloudDesk:
-- Built-in not_null cannot be applied to fct_tickets.closed_at because roughly 28%
-- (170 of 600) of tickets are legitimately 'open' and therefore have NULL closed_at.
-- However, business logic strictly requires:
--   1. Open tickets must NOT have a closed_at timestamp.
--   2. Closed or resolved tickets MUST have a closed_at timestamp >= opened_at.
--
-- Downstream impact if broken:
-- If an open ticket carries a closed_at timestamp, it will falsely enter closed-ticket
-- SLA denominators. If a closed/resolved ticket has NULL closed_at or closed_at < opened_at,
-- resolution_hours and is_sla_met become NULL or negative, corrupting average resolution
-- time and SLA compliance KPIs in fct_tickets.

select
    ticket_id,
    ticket_status,
    opened_at,
    closed_at
from {{ ref('fct_tickets') }}
where
    (ticket_status = 'open' and closed_at is not null)
    or (
        ticket_status in ('resolved', 'closed')
        and (closed_at is null or closed_at < opened_at)
    )
