DROP VIEW IF EXISTS evaluation_grade_current;
--
CREATE VIEW evaluation_grade_current AS
SELECT p.id AS evaluation_plan_id, g.name, g.lower_bound, g.upper_bound 
FROM evaluation_plans p
JOIN evaluation_grades g ON p.evaluation_grade_setting_id = g.evaluation_grade_setting_id
JOIN evaluation_grade_settings s ON s.id = g.evaluation_grade_setting_id
WHERE g.flag <> 'D'
ORDER BY p.id, g.upper_bound DESC