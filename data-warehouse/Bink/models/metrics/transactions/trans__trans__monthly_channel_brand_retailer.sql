/*
CREATED BY:         CHRISTOPHER MITCHELL
CREATED DATE:       2023-11-01
Last modified by:   Anand Bhakta
Last modified date: 2024-02-26

DESCRIPTION:
    TRANSACTION METRICS BY RETAILER ON A MONTHLY GRANULARITY. 
	INCREMENTAL STRATEGY: LOADS ALL NEWLY INSERTED RECORDS, TRANSFORMS, THEN LOADS
	ALL PREVIOUS PERIOD METRICS, FINALLY CALCULATING CUMULATIVE METRICS, AND MERGING BASED ON THE UNIQUE_KEY
NOTES:
    SOURCE_OBJECT       - TXNS_TRANS
                        - STG_METRICS__DIM_DATE
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
            inserted_date_time >= (select max(inserted_date_time) from {{ this }})
    {% endif %}
),

dim_date as (
    select distinct
        start_of_month,
        end_of_month
    from {{ ref("stg_metrics__dim_date") }}
    where date >= (select date(min(date)) from txn_events) and date <= current_date()
),

stage as (
    select
        user_ref,
        transaction_id,
        channel,
        brand,
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
       channel,
       brand,
       loyalty_plan_company,
       loyalty_plan_name,
        sum(
            case when status = 'TXNS' then spend_amount end
        ) as spend_amount_period_positive,
        sum(
            case when status = 'REFUND' then spend_amount end
        ) as refund_amount_period,
        sum(
            case when status in ('TXNS','REFUND') then spend_amount end
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
    left join dim_date d on d.start_of_month = date_trunc('month',date)
    group by d.start_of_month,channel,brand,loyalty_plan_company,loyalty_plan_name
),

txn_union as (
    select * from txn_period
    {% if is_incremental() %}
    union
    select
        date,
        channel,
        brand,
        loyalty_plan_company,
        loyalty_plan_name,
        T049__SPEND__monthly_channel_brand_retailer__SUM,
        T050__REFUND__monthly_channel_brand_retailer__SUM,
        T060__NET_SPEND__monthly_channel_brand_retailer__SUM,
        T053__BNPL_TXNS__monthly_channel_brand_retailer__DCOUNT,
        T051__TXNS__monthly_channel_brand_retailer__DCOUNT,
        T052__REFUND__monthly_channel_brand_retailer__DCOUNT,
        T057__DUPLICATE_TXN__monthly_channel_brand_retailer__DCOUNT
    from {{ this }}
    {% endif %}
),

txn_combine as (
    select
        date,
        channel,
        brand,
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
    group by date, channel, brand, loyalty_plan_company, loyalty_plan_name
),

txn_cumulative as (
    select
        date,
        channel,
        brand,
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
            partition by channel, brand, loyalty_plan_company order by date
        ) as cumulative_spend,
        sum(refund_amount_period) over (
            partition by channel, brand, loyalty_plan_company order by date
        ) as cumulative_refund,
        sum(net_spend_amount_period) over (
            partition by channel, brand, loyalty_plan_company order by date
        ) as cumulative_net_spend,
        sum(count_bnpl_period) over (
            partition by channel, brand, loyalty_plan_company order by date
        ) as cumulative_bnpl_txns,
        sum(count_transaction_period) over (
            partition by channel, brand, loyalty_plan_company order by date
        ) as cumulative_txns,
        sum(count_refund_period) over (
            partition by channel, brand, loyalty_plan_company order by date
        ) as cumulative_refund_txns,
        sum(count_dupe_period) over (
            partition by channel, brand, loyalty_plan_company order by date
        ) as cumulative_dupe_txns
    from txn_combine
),

finalise as 
    (select
        date,
        channel,
        brand,
        loyalty_plan_company,
        loyalty_plan_name,
        coalesce(cumulative_spend, 0) as T044__SPEND__monthly_channel_brand_retailer__CSUM,
        coalesce(cumulative_refund, 0) as T045__REFUND__monthly_channel_brand_retailer__CSUM,
        coalesce(cumulative_txns, 0) as T046__TXNS__MONTHLY_RETAILER_CAHNNEL__CSUM,
        coalesce(cumulative_refund_txns, 0) as T047__REFUND__monthly_channel_brand_retailer__CSUM,
        coalesce(cumulative_dupe_txns, 0) as T058__DUPLICATE_TXN__monthly_channel_brand_retailer__CSUM,
        coalesce(cumulative_bnpl_txns, 0) as T048__BNPL_TXNS__monthly_channel_brand_retailer__CSUM,
        coalesce(spend_amount_period_positive, 0) as T049__SPEND__monthly_channel_brand_retailer__SUM,
        coalesce(refund_amount_period, 0) as T050__REFUND__monthly_channel_brand_retailer__SUM,
        coalesce(count_transaction_period, 0) as T051__TXNS__monthly_channel_brand_retailer__DCOUNT,
        coalesce(count_refund_period, 0) as T052__REFUND__monthly_channel_brand_retailer__DCOUNT,
        coalesce(count_bnpl_period, 0) as T053__BNPL_TXNS__monthly_channel_brand_retailer__DCOUNT,
        coalesce(count_dupe_period, 0) as T057__DUPLICATE_TXN__monthly_channel_brand_retailer__DCOUNT,
        coalesce(net_spend_amount_period, 0) as T060__NET_SPEND__monthly_channel_brand_retailer__SUM,
        coalesce(net_spend_amount_period, 0) as T061__NET_SPEND__monthly_channel_brand_retailer__CSUM,
        T051__TXNS__monthly_channel_brand_retailer__DCOUNT+T052__REFUND__monthly_channel_brand_retailer__DCOUNT as t065__txns_and_refunds__monthly_channel_brand_retailer__dcount,
        T057__DUPLICATE_TXN__monthly_channel_brand_retailer__DCOUNT+T051__TXNS__monthly_channel_brand_retailer__DCOUNT as T066__TXNS_AND_DUPES__monthly_channel_brand_retailer__DCOUNT,
        DIV0(T057__DUPLICATE_TXN__monthly_channel_brand_retailer__DCOUNT,T066__TXNS_AND_DUPES__monthly_channel_brand_retailer__DCOUNT) as T059__DUPLICATE_TXN_PER_TXN__monthly_channel_brand_retailer__PERCENTAGE,
        sysdate() as inserted_date_time,
        MD5(date||loyalty_plan_company||loyalty_plan_name||channel||brand) as unique_key
    from txn_cumulative
)

select *
from finalise
