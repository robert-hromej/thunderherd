SELECT r.id,
       r.uuid,
       s.key           AS site,
       e.name          AS env,
       e.heroku_app,
       r.started_at,
       r.finished_at,
       r.label,
       r.is_baseline,
       r.status,
       o.name          AS operator,
       m.hostname      AS machine,
       d.heroku_release,
       d.git_sha,
       (SELECT string_agg(rd.process_type || '=' || rd.quantity || ':' || rd.size, ' '
                          ORDER BY rd.process_type)
          FROM run_dynos rd WHERE rd.run_id = r.id) AS dynos,
       r.requests_per_url,
       r.concurrency,
       r.tool_version,
       (SELECT count(*)             FROM results re WHERE re.run_id = r.id) AS pages,
       (SELECT sum(re.error_count)  FROM results re WHERE re.run_id = r.id) AS total_errors,
       (SELECT round(avg(re.p95_ms)) FROM results re WHERE re.run_id = r.id) AS avg_p95_ms
FROM runs r
JOIN environments e   ON e.id = r.environment_id
JOIN sites s          ON s.id = e.site_id
LEFT JOIN operators o  ON o.id = r.operator_id
LEFT JOIN machines m   ON m.id = r.machine_id
LEFT JOIN app_deploys d ON d.id = r.deploy_id
