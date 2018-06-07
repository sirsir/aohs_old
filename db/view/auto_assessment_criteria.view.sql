DROP VIEW IF EXISTS auto_assessment_criteria;
--
CREATE VIEW auto_assessment_criteria AS
SELECT p.id AS evaluation_plan_id, p.revision_no, c.evaluation_question_id, c.question_group_id, c.name
FROM evaluation_plans p
JOIN evaluation_criteria c ON p.id = c.evaluation_plan_id AND p.revision_no = c.revision_no
WHERE c.item_type = 'criteria'
AND p.flag <> 'D'
ORDER BY p.id, p.revision_no, c.order_no