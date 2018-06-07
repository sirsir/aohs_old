DROP VIEW IF EXISTS current_extension_agent_maps;
--
CREATE VIEW current_extension_agent_maps AS
(SELECT u.extension, u.did, u.agent_id, 1 AS priority_no 
FROM user_extension_maps u
WHERE u.agent_id > 0)
UNION
(SELECT e.number AS extension, d.number AS did, u.id AS agent_id, 99 AS priority_no
FROM extensions e  
JOIN users u ON e.user_id = u.id
LEFT JOIN dids d ON d.extension_id = e.id)
ORDER BY extension, priority_no