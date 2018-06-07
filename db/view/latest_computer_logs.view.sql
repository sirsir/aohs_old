DROP VIEW IF EXISTS latest_computer_logs;
--
CREATE VIEW latest_computer_logs AS
SELECT
	`computer_logs`.`remote_ip` AS `remote_ip`,
	max(
		`computer_logs`.`check_time`
	) AS `max_check_time`
FROM
	`computer_logs`
GROUP BY
	`computer_logs`.`remote_ip`