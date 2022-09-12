[OUTPUT]
    Name                         s3
    Match                        *
    region                       ${region}
    bucket                       ${s3_log_bucket}
    total_file_size              250M
    s3_key_format                /$TAG/%Y/%m/%d/%H/%M/%S/$UUID.gz
    s3_key_format_tag_delimiters .-