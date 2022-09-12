[OUTPUT]
    Name               cloudwatch_logs
    Match              *
    region             ${region}
    log_group_name     ${cloudwatch_log_group}
    log_stream_prefix  tfe-logs-prefix-