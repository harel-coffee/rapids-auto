rule histogram_phone_data_yield:
    input:
        "data/processed/features/all_participants/all_sensor_features.csv"
    output:
        "reports/data_exploration/histogram_phone_data_yield.html"
    script:
        "../src/visualization/histogram_phone_data_yield.py"

rule heatmap_sensors_per_minute_per_time_segment:
    input:
        phone_data_yield = "data/interim/{pid}/phone_yielded_timestamps_with_datetime.csv",
        participant_file = "data/external/participant_files/{pid}.yaml",
        time_segments_labels = "data/interim/time_segments/{pid}_time_segments_labels.csv"
    params:
        pid = "{pid}"
    output:
        "reports/interim/{pid}/heatmap_sensors_per_minute_per_time_segment.html"
    script:
        "../src/visualization/heatmap_sensors_per_minute_per_time_segment.py"

rule merge_heatmap_sensors_per_minute_per_time_segment:
    input:
        heatmap_sensors_per_minute_per_time_segment = expand("reports/interim/{pid}/heatmap_sensors_per_minute_per_time_segment.html", pid=config["PIDS"])
    output:
        "reports/data_exploration/heatmap_sensors_per_minute_per_time_segment.html"
    script:
        "../src/visualization/merge_heatmap_sensors_per_minute_per_time_segment.Rmd"

rule heatmap_sensor_row_count_per_time_segment:
    input:
        all_sensors = expand("data/raw/{{pid}}/{sensor}_with_datetime.csv", sensor = map(str.lower, config["HEATMAP_SENSOR_ROW_COUNT_PER_TIME_SEGMENT"]["SENSORS"])),
        phone_data_yield = "data/processed/features/{pid}/phone_data_yield.csv",
        participant_file = "data/external/participant_files/{pid}.yaml",
        time_segments_labels = "data/interim/time_segments/{pid}_time_segments_labels.csv"
    params:
        pid = "{pid}"
    output:
        "reports/interim/{pid}/heatmap_sensor_row_count_per_time_segment.html"
    script:
        "../src/visualization/heatmap_sensor_row_count_per_time_segment.py"

rule merge_heatmap_sensor_row_count_per_time_segment:
    input:
        heatmap_sensor_row_count_per_time_segment = expand("reports/interim/{pid}/heatmap_sensor_row_count_per_time_segment.html", pid=config["PIDS"])
    output:
        "reports/data_exploration/heatmap_sensor_row_count_per_time_segment.html"
    script:
        "../src/visualization/merge_heatmap_sensor_row_count_per_time_segment.Rmd"

rule heatmap_phone_data_yield_per_participant_per_time_segment:
    input:
        phone_data_yield = expand("data/processed/features/{pid}/phone_data_yield.csv", pid=config["PIDS"]),
        participant_file = expand("data/external/participant_files/{pid}.yaml", pid=config["PIDS"]),
        time_segments_labels = expand("data/interim/time_segments/{pid}_time_segments_labels.csv", pid=config["PIDS"])
    output:
        "reports/data_exploration/heatmap_phone_data_yield_per_participant_per_time_segment.html"
    script:
        "../src/visualization/heatmap_phone_data_yield_per_participant_per_time_segment.py"

rule heatmap_feature_correlation_matrix:
    input:
        all_sensor_features = "data/processed/features/all_participants/all_sensor_features.csv" # before data cleaning
    params:
        min_rows_ratio = config["HEATMAP_FEATURE_CORRELATION_MATRIX"]["MIN_ROWS_RATIO"],
        corr_threshold = config["HEATMAP_FEATURE_CORRELATION_MATRIX"]["CORR_THRESHOLD"],
        corr_method = config["HEATMAP_FEATURE_CORRELATION_MATRIX"]["CORR_METHOD"]
    output:
        "reports/data_exploration/heatmap_feature_correlation_matrix.html"
    script:
        "../src/visualization/heatmap_feature_correlation_matrix.py"

