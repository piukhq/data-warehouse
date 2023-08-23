/*
Created by:         Sam Pibworth
Created date:       2022-06-15
Last modified by:   
Last modified date: 

Description:
	Fact payment account with reduced columns

Parameters:
    ref_object      - fact_payment_account_secure
*/
{{
    config(
        materialized="incremental",
        unique_key="EVENT_ID",
        merge_update_columns=["IS_MOST_RECENT", "UPDATED_DATE_TIME"],
    )
}}

with
    pa as (
        select *
        from {{ ref("fact_payment_account_secure") }}
        {% if is_incremental() %}
        where updated_date_time >= (select max(updated_date_time) from {{ this }})
        {% endif %}
    ),
    pa_select as (
        select
            event_id,
            event_date_time,
            event_type,
            payment_account_id,
            is_most_recent,
            origin,
            channel,
            brand,
            user_id / /,
            external_user_ref / /,
            expiry_date,
            token,
            status_id,
            status,
            email_domain,
            inserted_date_time,
            updated_date_time
        from pa
    )

select *
from pa_select
