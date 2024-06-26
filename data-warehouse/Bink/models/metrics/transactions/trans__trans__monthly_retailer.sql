/*
Created by:         Christopher Mitchell
Created date:       2023-07-17
Last modified by:   Anand Bhakta
Last modified date: 2024-02-26

Description:
    Transaction metrics by retailer on a monthly granularity. 
	INCREMENTAL STRATEGY: LOADS ALL NEWLY INSERTED RECORDS, TRANSFORMS, THEN LOADS
	ALL PREVIOUS PERIOD METRICS, FINALLY CALCULATING CUMULATIVE METRICS, AND MERGING BASED ON THE UNIQUE_KEY
Notes:
    source_object       - txns_trans
                        - stg_metrics__dim_date
*/

{{
    config(
        materialized="table",
        unique_key="UNIQUE_KEY"
    )
}}

with
txn_events as (select * from {{ ref("txns_trans") }}    
    {% if is_incremental() %}
            where
            inserted_date_time >= (select date(max(inserted_date_time)) from {{ this }})
    {% endif %}
),

dim_date as (
    select distinct
        start_of_month,
        end_of_month
    from {{ ref("stg_metrics__dim_date") }}
    where date >= (select min(date) from txn_events) and date <= current_date()
),

stage as (
    select
        user_ref,
        transaction_id,
        loyalty_plan_name,
        loyalty_plan_company,
        status,
        date_trunc('month', date) as date,
        spend_amount,
        loyalty_card_id
    from txn_events
),

txn_period as (
    select
        d.start_of_month as date,
        s.loyalty_plan_company,
        s.loyalty_plan_name,
        sum(
            case when status = 'TXNS' then s.spend_amount end
        ) as spend_amount_period_positive,
        sum(
            case when status = 'REFUND' then s.spend_amount end
        ) as refund_amount_period,
        sum(
            case when status in ('TXNS','REFUND') then s.spend_amount end
        ) as net_spend_amount_period,
        count(
            distinct case when status = 'BNPL' then transaction_id end
        ) as count_bnpl_period,
        count(
            distinct case when status = 'TXNS' then transaction_id end
        ) as count_transaction_period,
        count(
            distinct case when status = 'REFUND' then transaction_id end
        ) as count_refund_period,
        count(
            distinct case when status = 'DUPLICATE' then transaction_id end
        ) as count_dupe_period
    from stage s
    left join dim_date d on d.start_of_month = date_trunc('month', s.date)
    group by d.start_of_month, s.loyalty_plan_company, s.loyalty_plan_name
),

txn_union as (
    select * from txn_period
    {% if is_incremental() %}
    union
    select
        date,
        loyalty_plan_company,
        loyalty_plan_name,
        t009__spend__monthly_retailer__sum,
        t010__refund__monthly_retailer__sum,
        t020__net_spend__monthly_retailer__sum,
        t013__bnpl_txns__monthly_retailer__dcount,
        t011__txns__monthly_retailer__dcount,
        t012__refund__monthly_retailer__dcount,
        t017__duplicate_txn__monthly_retailer__dcount
    from {{ this }}
    {% endif %}
),

txn_combine as (
    select
        date,
        loyalty_plan_company,
        loyalty_plan_name,
        sum(spend_amount_period_positive) as spend_amount_period_positive,
        sum(refund_amount_period) as refund_amount_period,
        sum(net_spend_amount_period) as net_spend_amount_period,
        sum(count_bnpl_period) as count_bnpl_period,
        sum(count_transaction_period) as count_transaction_period,
        sum(count_refund_period) as count_refund_period,
        sum(count_dupe_period) as count_dupe_period
    from txn_union
    group by date, loyalty_plan_company, loyalty_plan_name
),

txn_cumulative as (
    select
        date,
        loyalty_plan_company,
        loyalty_plan_name,
        spend_amount_period_positive,
        refund_amount_period,
        net_spend_amount_period,
        count_bnpl_period,
        count_transaction_period,
        count_refund_period,
        count_dupe_period,
        sum(spend_amount_period_positive) over (
            partition by loyalty_plan_company order by date
        ) as cumulative_spend,
        sum(refund_amount_period) over (
            partition by loyalty_plan_company order by date
        ) as cumulative_refund,
        sum(net_spend_amount_period) over (
            partition by loyalty_plan_company order by date
        ) as cumulative_net_spend,
        sum(count_bnpl_period) over (
            partition by loyalty_plan_company order by date
        ) as cumulative_bnpl_txns,
        sum(count_transaction_period) over (
            partition by loyalty_plan_company order by date
        ) as cumulative_txns,
        sum(count_refund_period) over (
            partition by loyalty_plan_company order by date
        ) as cumulative_refund_txns,
        sum(count_dupe_period) over (
            partition by loyalty_plan_company order by date
        ) as cumulative_dupe_txns
    from txn_combine
),

finalise as 
    (select
        date,
        loyalty_plan_company,
        loyalty_plan_name,
        coalesce(cumulative_spend,0) as t004__spend__monthly_retailer__csum,
        coalesce(cumulative_refund,0) as t005__refund__monthly_retailer__csum,
        coalesce(cumulative_txns,0) as t006__txns__monthly_retailer__csum,
        coalesce(cumulative_refund_txns,0) as t007__refund__monthly_retailer__csum,
        coalesce(cumulative_dupe_txns,0) as t018__duplicate_txn__monthly_retailer__csum,
        coalesce(cumulative_bnpl_txns,0) as t008__bnpl_txns__monthly_retailer__csum,
        coalesce(spend_amount_period_positive,0) as t009__spend__monthly_retailer__sum,
        coalesce(refund_amount_period,0) as t010__refund__monthly_retailer__sum,
        coalesce(count_transaction_period,0) as t011__txns__monthly_retailer__dcount,
        coalesce(count_refund_period,0) as t012__refund__monthly_retailer__dcount,
        coalesce(count_bnpl_period,0) as t013__bnpl_txns__monthly_retailer__dcount,
        coalesce(count_dupe_period,0) as t017__duplicate_txn__monthly_retailer__dcount,
        coalesce(net_spend_amount_period,0) as t020__net_spend__monthly_retailer__sum,
        coalesce(net_spend_amount_period,0) as t021__net_spend__monthly_retailer__csum,
        t011__txns__monthly_retailer__dcount+t012__refund__monthly_retailer__dcount as t025__txns_and_refunds__monthly_retailer__dcount,
        t017__duplicate_txn__monthly_retailer__dcount+t011__txns__monthly_retailer__dcount as t026__txns_and_dupes__monthly_retailer__dcount,
        DIV0(t017__duplicate_txn__monthly_retailer__dcount,t026__txns_and_dupes__monthly_retailer__dcount) as t019__duplicate_txn_per_txn__monthly_retailer__percentage,
        sysdate() as inserted_date_time,
        MD5(date||loyalty_plan_company||loyalty_plan_name) as unique_key
    from txn_cumulative
)


select *
from finalise
