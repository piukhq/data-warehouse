/*
Created by:         Anand Bhakta
Created date:       2023-02-05
Last modified by:   
Last modified date: 

Description:
    Rewrite of the LL table lc_joins_links_snapshot and lc_joins_links containing both snapshot and daily absolute data of all link and join journeys split by RETAILER.
Notes:
    This code can be made more efficient if the start is pushed to the trans__lbg_user code and that can be the source for the majority of the dashboards including user_loyalty_plan_snapshot and user_with_loyalty_cards
Parameters:
    source_object       - src__fact_lc_add
                        - src__fact_lc_removed
                        - src__dim_loyalty_card
                        - src__dim_date
*/

WITH lc_events AS (
    SELECT *
    FROM {{ref('lc_trans')}}
)

,dim_date AS (
    SELECT *
    FROM {{ref('src__dim_date')}}
    WHERE
        DATE >= (SELECT MIN(FROM_DATE) FROM lc_events)
        AND DATE <= CURRENT_DATE()
)
        
,count_up_snap AS (
  SELECT
    d.DATE
    ,u.CHANNEL
    ,u.BRAND
    ,u.LOYALTY_PLAN_NAME
    ,u.LOYALTY_PLAN_COMPANY
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'SUCCESS' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)  AS JOIN_SUCCESS_STATE
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'FAILED' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)   AS JOIN_FAILED_STATE
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REQUEST' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)  AS JOIN_PENDING_STATE
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REMOVED' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)   AS JOIN_REMOVED_STATE
  
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'SUCCESS' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)  AS LINK_SUCCESS_STATE
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'FAILED' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)   AS LINK_FAILED_STATE
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REQUEST' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)  AS LINK_PENDING_STATE
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REMOVED' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)   AS LINK_REMOVED_STATE
FROM lc_events u
LEFT JOIN dim_date d
    ON d.DATE >= DATE(u.FROM_DATE)
    AND d.DATE < COALESCE(DATE(u.TO_DATE), '9999-12-31')
GROUP BY
    d.DATE
    ,u.BRAND
    ,u.CHANNEL
    ,u.LOYALTY_PLAN_NAME
    ,u.LOYALTY_PLAN_COMPANY
HAVING DATE IS NOT NULL
)    

,count_up_abs AS (
  SELECT
    d.DATE
    ,u.CHANNEL
    ,u.BRAND
    ,u.LOYALTY_PLAN_NAME
    ,u.LOYALTY_PLAN_COMPANY
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REQUEST' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)  AS JOIN_REQUESTS
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'FAILED' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)   AS JOIN_FAILS
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'SUCCESS' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)  AS JOIN_SUCCESSES
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REMOVED' AND ADD_JOURNEY = 'JOIN' THEN 1 END),0)   AS JOIN_DELETES
  
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REQUEST' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)  AS LINK_REQUESTS
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'FAILED' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)   AS LINK_FAILS
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'SUCCESS' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)  AS LINK_SUCCESSES
        ,COALESCE(SUM(CASE WHEN EVENT_TYPE = 'REMOVED' AND ADD_JOURNEY = 'LINK' THEN 1 END),0)   AS LINK_DELETES


        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'REQUEST' AND ADD_JOURNEY = 'JOIN' THEN u.USER_REF END),0)  AS JOIN_REQUESTS_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'FAILED' AND ADD_JOURNEY = 'JOIN' THEN u.USER_REF END),0)   AS JOIN_FAILS_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'SUCCESS' AND ADD_JOURNEY = 'JOIN' THEN u.USER_REF END),0)  AS JOIN_SUCCESSES_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'REMOVED' AND ADD_JOURNEY = 'JOIN' THEN u.USER_REF END),0)   AS JOIN_DELETES_UNIQUE_USERS
  
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'REQUEST' AND ADD_JOURNEY = 'LINK' THEN u.USER_REF END),0)  AS LINK_REQUESTS_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'FAILED' AND ADD_JOURNEY = 'LINK' THEN u.USER_REF END),0)   AS LINK_FAILS_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'SUCCESS' AND ADD_JOURNEY = 'LINK' THEN u.USER_REF END),0)  AS LINK_SUCCESSES_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'REMOVED' AND ADD_JOURNEY = 'LINK' THEN u.USER_REF END),0)   AS LINK_DELETES_UNIQUE_USERS

        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'REQUEST' THEN u.USER_REF END),0)   AS REQUESTS_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'FAILED' THEN u.USER_REF END),0)    AS FAILS_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'SUCCESS' THEN u.USER_REF END),0)   AS SUCCESSES_UNIQUE_USERS
        ,COALESCE(COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'REMOVED' THEN u.USER_REF END),0)    AS DELETES_UNIQUE_USERS

FROM lc_events u
LEFT JOIN dim_date d
    ON d.DATE = DATE(u.FROM_DATE)
GROUP BY
    d.DATE
    ,u.BRAND
    ,u.CHANNEL
    ,u.LOYALTY_PLAN_NAME
    ,u.LOYALTY_PLAN_COMPANY
HAVING DATE IS NOT NULL
)

,all_together AS (
    SELECT
        COALESCE(a.date,s.date) DATE
        ,COALESCE(a.brand,s.brand) BRAND
        ,COALESCE(a.CHANNEL,s.CHANNEL) CHANNEL
        ,COALESCE(a.LOYALTY_PLAN_NAME,s.LOYALTY_PLAN_NAME) LOYALTY_PLAN_NAME
        ,COALESCE(a.LOYALTY_PLAN_COMPANY,s.LOYALTY_PLAN_COMPANY) LOYALTY_PLAN_COMPANY

        ,COALESCE(s.JOIN_SUCCESS_STATE,0)   AS JOIN_SUCCESS_STATE
        ,COALESCE(s.JOIN_FAILED_STATE,0)    AS JOIN_FAILED_STATE
        ,COALESCE(s.JOIN_PENDING_STATE,0)   AS JOIN_PENDING_STATE
        ,COALESCE(s.JOIN_REMOVED_STATE,0)   AS JOIN_REMOVED_STATE
        ,COALESCE(s.LINK_SUCCESS_STATE,0)   AS LINK_SUCCESS_STATE
        ,COALESCE(s.LINK_FAILED_STATE,0)    AS LINK_FAILED_STATE
        ,COALESCE(s.LINK_PENDING_STATE,0)   AS LINK_PENDING_STATE
        ,COALESCE(s.LINK_REMOVED_STATE,0)   AS LINK_REMOVED_STATE

        ,COALESCE(a.JOIN_REQUESTS,0)    AS JOIN_REQUESTS
        ,COALESCE(a.JOIN_FAILS,0)       AS JOIN_FAILS
        ,COALESCE(a.JOIN_SUCCESSES,0)   AS JOIN_SUCCESSES
        ,COALESCE(a.JOIN_DELETES,0)     AS JOIN_DELETES
        ,COALESCE(a.LINK_REQUESTS,0)    AS LINK_REQUESTS
        ,COALESCE(a.LINK_FAILS,0)       AS LINK_FAILS
        ,COALESCE(a.LINK_SUCCESSES,0)   AS LINK_SUCCESSES
        ,COALESCE(a.LINK_DELETES,0)     AS LINK_DELETES

        ,COALESCE(a.JOIN_REQUESTS_UNIQUE_USERS,0)   AS JOIN_REQUESTS_UNIQUE_USERS
        ,COALESCE(a.JOIN_FAILS_UNIQUE_USERS,0)      AS JOIN_FAILS_UNIQUE_USERS
        ,COALESCE(a.JOIN_SUCCESSES_UNIQUE_USERS,0)  AS JOIN_SUCCESSES_UNIQUE_USERS
        ,COALESCE(a.JOIN_DELETES_UNIQUE_USERS,0)    AS JOIN_DELETES_UNIQUE_USERS
        ,COALESCE(a.LINK_REQUESTS_UNIQUE_USERS,0)   AS LINK_REQUESTS_UNIQUE_USERS
        ,COALESCE(a.LINK_FAILS_UNIQUE_USERS,0)      AS LINK_FAILS_UNIQUE_USERS
        ,COALESCE(a.LINK_SUCCESSES_UNIQUE_USERS,0)  AS LINK_SUCCESSES_UNIQUE_USERS
        ,COALESCE(a.LINK_DELETES_UNIQUE_USERS,0)    AS LINK_DELETES_UNIQUE_USERS
    FROM count_up_abs a
    FULL OUTER JOIN count_up_snap s     
        ON a.date=s.date and a.brand = s.brand and a.loyalty_plan_name = s.loyalty_plan_name
)

,add_combine_rename AS (
    SELECT
        DATE
        ,CHANNEL
        ,BRAND
        ,LOYALTY_PLAN_NAME
        ,LOYALTY_PLAN_COMPANY

        ,JOIN_SUCCESS_STATE                                          AS LC029__SUCCESSFUL_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,JOIN_FAILED_STATE                                           AS LC031__FAILED_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,JOIN_PENDING_STATE                                          AS LC030__REQUESTS_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,JOIN_REMOVED_STATE                                          AS LC032__DELETED_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,LINK_SUCCESS_STATE                                          AS LC025__SUCCESSFUL_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,LINK_FAILED_STATE                                           AS LC027__FAILED_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,LINK_PENDING_STATE                                          AS LC026__REQUESTS_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,LINK_REMOVED_STATE                                          AS LC028__DELETED_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,JOIN_SUCCESS_STATE+LINK_SUCCESS_STATE                       AS LC001__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,JOIN_PENDING_STATE+LINK_PENDING_STATE                       AS LC002__REQUESTS_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,JOIN_FAILED_STATE+LINK_FAILED_STATE                         AS LC003__FAILED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT
        ,LINK_REMOVED_STATE+JOIN_REMOVED_STATE                       AS LC004__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__PIT

        ,JOIN_REQUESTS                                              AS LC014__REQUESTS_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,JOIN_FAILS                                                 AS LC015__FAILED_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,JOIN_SUCCESSES                                             AS LC013__SUCCESSFUL_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,JOIN_DELETES                                               AS LC016__DELETED_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,LINK_REQUESTS                                              AS LC010__REQUESTS_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,LINK_FAILS                                                 AS LC011__FAILED_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,LINK_SUCCESSES                                             AS LC009__SUCCESSFUL_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,LINK_DELETES                                               AS LC012__DELETED_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,JOIN_REQUESTS + LINK_REQUESTS                              AS LC006__REQUESTS_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,JOIN_FAILS + LINK_FAILS                                    AS LC007__FAILED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,JOIN_SUCCESSES + LINK_SUCCESSES                            AS LC005__SUCCESSFUL_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT
        ,JOIN_DELETES + LINK_DELETES                                AS LC008__DELETED_LOYALTY_CARDS__DAILY_CHANNEL_BRAND_RETAILER__COUNT

        ,JOIN_REQUESTS_UNIQUE_USERS                                 AS LC018__REQUESTS_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER
        ,JOIN_FAILS_UNIQUE_USERS                                    AS LC023__FAILED_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER
        ,JOIN_SUCCESSES_UNIQUE_USERS                                AS LC021__SUCCESSFUL_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER
        ,JOIN_DELETES_UNIQUE_USERS                                  AS LC024__DELETED_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER
        ,LINK_REQUESTS_UNIQUE_USERS                                 AS LC022__REQUESTS_LOYALTY_CARD_JOINS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER
        ,LINK_FAILS_UNIQUE_USERS                                    AS LC019__FAILED_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER
        ,LINK_SUCCESSES_UNIQUE_USERS                                AS LC017__SUCCESSFUL_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER
        ,LINK_DELETES_UNIQUE_USERS                                  AS LC020__DELETED_LOYALTY_CARD_LINKS__DAILY_CHANNEL_BRAND_RETAILER__DCOUNT_USER

    FROM all_together
)

select * 
from add_combine_rename
