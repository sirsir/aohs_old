DROP VIEW IF EXISTS tags_maps;
--
CREATE VIEW tags_maps AS
SELECT
	`t1`.`id` AS `id`,
	`t1`.`name` AS `name`,

IF (
	isnull(`t2`.`id`),
	`t1`.`id`,
	`t2`.`id`
) AS `tag_category_id`,

IF (
	isnull(`t2`.`id`),
	`t1`.`name`,
	`t2`.`name`
) AS `tag_category_name`,

IF (isnull(`t2`.`id`), 'C', '') AS `is_tag_category`
FROM
	(
		`tags` `t1`
		LEFT JOIN `tags` `t2` ON (
			(`t1`.`parent_id` = `t2`.`id`)
		)
	)