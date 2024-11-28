SELECT RIGHT('0' + CAST(@TimeInt / 100 AS VARCHAR(2)), 2) + ':' + RIGHT('0' + CAST(@TimeInt % 100 AS VARCHAR(2)), 2) AS FormattedTime
