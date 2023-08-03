/*
Created by:         Anand Bhakta
Created date:       2023-05-23
Last modified by:   Christopher Mitchell
Last modified date: 2023-06-07

Description:
    Datasource to produce lloyds mi dashboard - users_overview
Parameters:
    source_object       - lc__links_joins__daily_retailer_channel
                        - lc__links_joins__daily_channel
                        - user__transactions__daily_user_level
                        - user__registrations__daily__channel_brand 
*/

WITH lc_metrics_retailer AS (
    SELECT 
        *
        ,'LC_RETAILER_CHANNEL' AS TAB
    FROM {{ref('lc__links_joins__daily_retailer_channel')}}
    WHERE CHANNEL = 'LLOYDS'
    AND LOYALTY_PLAN_COMPANY NOT IN ('Bink Sweet Shop', 'Loyalteas')
)

,lc_metrics AS (
    SELECT 
        *
        ,'LC_CHANNEL' AS TAB
    FROM {{ref('user__loyalty_card__daily_channel_brand')}}
    WHERE CHANNEL = 'LLOYDS'
)

,active_usr AS (
    SELECT
        *
        ,'ACTIVE_USER' AS TAB
    FROM {{ref('user__transactions__daily_user_level')}}
    WHERE CHANNEL = 'LLOYDS'
    AND LOYALTY_PLAN_COMPANY NOT IN ('Bink Sweet Shop', 'Loyalteas')
)

,txn AS (
    SELECT
        *
        ,'TRANS' AS TAB
    FROM {{ref('trans__trans__daily_user_level')}}
    WHERE CHANNEL = 'LLOYDS'
    AND LOYALTY_PLAN_COMPANY NOT IN ('Bink Sweet Shop', 'Loyalteas')
)

,users_metrics AS (
    SELECT
        *
        ,'USERS' AS TAB
    FROM {{ref('user__registrations__daily_channel_brand')}}
    WHERE CHANNEL = 'LLOYDS'
)

,metric_select AS (
    SELECT
        TAB
        ,DATE
        ,CHANNEL
        ,BRAND
        ,LOYALTY_PLAN_COMPANY
        ,LC001__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS U003__USERS_WITH_A_LINKED_LOYALTY_CARD__DAILY_CHANNEL_BRAND__PIT
        ,LC004__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,LC005__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,LC008__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS U005__REGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U006__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U001__REGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS U002__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS T001__SPEND__USER_LEVEL_DAILY__SUM
        ,NULL AS U007__ACTIVE_USERS__USER_LEVEL_DAILY__UID
        ,NULL AS T003__TRANSACTIONS__USER_LEVEL_DAILY__DCOUNT_TXN
    FROM
        lc_metrics_retailer

    UNION ALL

    SELECT
        TAB
        ,DATE
        ,CHANNEL
        ,BRAND
        ,NULL AS LOYALTY_PLAN_COMPANY
        ,NULL AS LC001__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,U003__USERS_WITH_A_LINKED_LOYALTY_CARD__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS LC004__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS LC005__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS LC008__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS U005__REGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U006__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U001__REGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS U002__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS T001__SPEND__USER_LEVEL_DAILY__SUM
        ,NULL AS U007__ACTIVE_USERS__USER_LEVEL_DAILY__UID
        ,NULL AS T003__TRANSACTIONS__USER_LEVEL_DAILY__DCOUNT_TXN
    FROM
        lc_metrics    

    UNION ALL

    SELECT
        TAB
        ,DATE
        ,CHANNEL
        ,BRAND
        ,LOYALTY_PLAN_COMPANY
        ,NULL AS LC001__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS U003__USERS_WITH_A_LINKED_LOYALTY_CARD__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS LC004__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS LC005__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS LC008__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS U005__REGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U006__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U001__REGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS U002__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,T001__SPEND__USER_LEVEL_DAILY__SUM
        ,NULL AS U007__ACTIVE_USERS__USER_LEVEL_DAILY__UID
        ,T003__TRANSACTIONS__USER_LEVEL_DAILY__DCOUNT_TXN
    FROM    
        txn

    UNION ALL

    SELECT
        TAB
        ,DATE
        ,CHANNEL
        ,BRAND
        ,LOYALTY_PLAN_COMPANY
        ,NULL AS LC001__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS U003__USERS_WITH_A_LINKED_LOYALTY_CARD__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS LC004__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS LC005__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS LC008__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS U005__REGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U006__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,NULL AS U001__REGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS U002__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS T001__SPEND__USER_LEVEL_DAILY__SUM
        ,U007__ACTIVE_USERS__USER_LEVEL_DAILY__UID
        ,NULL AS T003__TRANSACTIONS__USER_LEVEL_DAILY__DCOUNT_TXN
    FROM    
        active_usr

    UNION ALL

    SELECT
        TAB
        ,DATE
        ,CHANNEL
        ,BRAND
        ,NULL AS LOYALTY_PLAN_COMPANY
        ,NULL AS LC001__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS U003__USERS_WITH_A_LINKED_LOYALTY_CARD__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS LC004__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,NULL AS LC005__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,NULL AS LC008__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,U005__REGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,U006__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__COUNT
        ,U001__REGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,U002__DEREGISTERED_USERS__DAILY_CHANNEL_BRAND__PIT
        ,NULL AS T001__SPEND__USER_LEVEL_DAILY__SUM
        ,NULL AS U007__ACTIVE_USERS__USER_LEVEL_DAILY__UID
        ,NULL AS T003__TRANSACTIONS__USER_LEVEL_DAILY__DCOUNT_TXN
    FROM
        users_metrics
)

select * from metric_select
