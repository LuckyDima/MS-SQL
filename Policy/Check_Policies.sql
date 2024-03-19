CREATE OR ALTER VIEW Check_Policies
AS
WITH History AS
(
    SELECT policy_id, MAX(history_id) history_id 
    FROM msdb.dbo.syspolicy_policy_execution_history (NOLOCK)
    GROUP BY policy_id
) 
SELECT 
    P.name, 
    HS.target_query_expression, 
    CAST(HD.result_detail AS XML).value('(Operator/ResultValue)[1]', 'NVARCHAR(MAX)') ResultValue
FROM msdb.dbo.syspolicy_policies P (NOLOCK)
JOIN msdb.dbo.syspolicy_policy_categories PC (NOLOCK) ON P.policy_category_id = PC.policy_category_id
JOIN msdb.dbo.syspolicy_system_health_state HS (NOLOCK) ON P.policy_id = HS.policy_id
JOIN History H ON H.policy_id = P.policy_id
JOIN msdb.dbo.syspolicy_policy_execution_history_details HD (NOLOCK) ON H.history_id = HD.history_id
WHERE PC.name = N'Internal Check' AND P.is_enabled = 1 AND HS.target_query_expression = HD.target_query_expression
