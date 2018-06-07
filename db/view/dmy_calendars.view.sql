DROP VIEW IF EXISTS dmy_calendars;
--
CREATE VIEW dmy_calendars AS
SELECT
	max(`statistic_calendars`.`id`) AS `id`,
	`statistic_calendars`.`stats_date` AS `stats_date`,
	`statistic_calendars`.`stats_day` AS `stats_day`,
	`statistic_calendars`.`stats_year` AS `stats_year`,
	`statistic_calendars`.`stats_week` AS `stats_week`,
	(
		`statistic_calendars`.`stats_week` + (
			`statistic_calendars`.`stats_year` * 100
		)
	) AS `stats_yearweek`,
	`statistic_calendars`.`stats_yearmonth` AS `stats_yearmonth`
FROM
	`statistic_calendars`
WHERE
	(
		`statistic_calendars`.`stats_hour` < 0
	)
GROUP BY
	`statistic_calendars`.`stats_date`,
	`statistic_calendars`.`stats_day`,
	`statistic_calendars`.`stats_hour`,
	`statistic_calendars`.`stats_year`,
	`statistic_calendars`.`stats_yearmonth`
