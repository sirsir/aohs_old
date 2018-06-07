DROP VIEW IF EXISTS evaluation_question_display;
--
CREATE VIEW evaluation_question_display AS
SELECT 
g.id AS question_group_id, g.title AS question_group_title, g.order_no AS group_order_no,
q.id AS question_id, q.title AS question_title, q.order_no AS order_no
FROM evaluation_question_groups g 
JOIN evaluation_questions q
ON g.id = q.question_group_id
ORDER BY g.title, q.title