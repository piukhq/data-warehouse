/*
 Test to ensure every active barclays loyalty card is matched with a payment card
 
 Created By:     SP
 Created Date:   2022/07/19
 */

{{ config(
        tags=['business']
        ,error_if = '>100'
        ,warn_if = '>100'
        ,meta={"description": "Test to ensure all active Barcalys loyalty cards are linked to a payment card.", 
            "test_type": "Business"},
) }}

WITH new_lc AS (
    SELECT *
    FROM
        {{ref('fact_loyalty_card')}}
    WHERE
        AUTH_TYPE in ('REGISTER', 'JOIN')
        AND EVENT_TYPE = 'SUCCESS'
        AND CHANNEL LIKE '%barclays%'
        AND TIMEDIFF(
                    HOUR, EVENT_DATE_TIME, (
                        SELECT MAX(EVENT_DATE_TIME)
                        FROM {{ref('fact_loyalty_card')}}
                        )
                    ) < 24
)
  
SELECT
    USER_ID
FROM
    new_lc
WHERE
    USER_ID NOT IN (SELECT USER_ID FROM {{ref('fact_payment_account')}})
