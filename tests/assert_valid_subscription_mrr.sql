-- Custom SQL Business Rule Test: Valid Subscription MRR Range
--
-- Why it matters for CloudDesk:
-- Raw subscriptions contains 17 sentinel outlier rows with mrr = 99999 across all
-- plan tiers (Starter, Business, Team, Enterprise), whereas legitimate plans range
-- from $49 to $4,999. stg_subscriptions converts 99999 to NULL and marks is_mrr_outlier.
--
-- Downstream impact if broken:
-- If staging fails to filter out 99999 sentinel values (or if another invalid MRR
-- like <= 0 or >= 99999 enters), int_account_rollup sums those sentinel values directly
-- into dim_accounts.active_mrr, massively overstating total CloudDesk ARR/MRR.

select
    subscription_id,
    account_id,
    plan_name,
    mrr
from {{ ref('stg_subscriptions') }}
where mrr is not null
  and (mrr <= 0 or mrr >= 99999)
