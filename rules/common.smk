# Features.smk #########################################################################################################
def find_features_files(wildcards):
    feature_files = []
    for provider_key, provider in config[(wildcards.sensor_key).upper()]["PROVIDERS"].items():
        if provider["COMPUTE"]:
            feature_files.extend(expand("data/interim/{{pid}}/{sensor_key}_features/{sensor_key}_{language}_{provider_key}.csv", sensor_key=wildcards.sensor_key.lower(), language=provider["SRC_LANGUAGE"].lower(), provider_key=provider_key.lower()))
    return(feature_files)

def optional_steps_sleep_input(wildcards):
    if config["STEP"]["EXCLUDE_SLEEP"]["EXCLUDE"] == True and config["STEP"]["EXCLUDE_SLEEP"]["TYPE"] == "FITBIT_BASED":
        return  "data/raw/{pid}/fitbit_sleep_summary_with_datetime.csv"
    else:
        return []

def input_merge_sensor_features_for_individual_participants(wildcards):
    feature_files = []
    for config_key in config.keys():
        if config_key.startswith(("PHONE", "FITBIT", "EMPATICA")) and "PROVIDERS" in config[config_key] and isinstance(config[config_key]["PROVIDERS"], dict):
            for provider_key, provider in config[config_key]["PROVIDERS"].items():
                if "COMPUTE" in provider.keys() and provider["COMPUTE"]:
                    feature_files.append("data/processed/features/{pid}/" + config_key.lower() + ".csv")
                    break
    return feature_files

def get_phone_sensor_names():
    phone_sensor_names = []
    for config_key in config.keys():
        if config_key.startswith(("PHONE")) and "PROVIDERS" in config[config_key]:
            if config_key != "PHONE_DATA_YIELD" and config_key not in phone_sensor_names:
                    phone_sensor_names.append(config_key)
    return phone_sensor_names

def download_phone_data_input_with_mutation_scripts(wilcards):
    import yaml
    input = dict()
    phone_source_type = config["PHONE_DATA_CONFIGURATION"]["SOURCE"]["TYPE"]

    input["participant_file"] = "data/external/participant_files/{pid}.yaml"
    input["rapids_schema_file"] = "src/data/streams/rapids_columns.yaml"
    input["source_schema_file"] = "src/data/streams/" + phone_source_type + "/format.yaml"
    input["source_download_file"] = "src/data/streams/"+ phone_source_type + "/container.R"

    schema = yaml.load(open(input.get("source_schema_file"), 'r'), Loader=yaml.FullLoader)
    sensor = ("phone_" + wilcards.sensor).upper()
    if sensor not in schema:
        raise ValueError("{sensor} is not defined in the schema {schema}".format(sensor=sensor, schema=input.get("source_schema_file")))
    for device_os in ["ANDROID", "IOS"]:
        scripts = schema[sensor][device_os]["MUTATION_SCRIPTS"]
        if isinstance(scripts, list):
            for idx, script in enumerate(scripts):
                if not script.lower().endswith((".py", ".r")):
                    raise ValueError("Mutate scripts can only be Python or R scripts (.py, .R).\n   Instead we got {script} in \n   [{sensor}][{device_os}] of {schema}".format(script=script, sensor=sensor, device_os=device_os, schema=input.get("source_schema_file")))
                input["mutationscript"+str(idx)] = script
    return input

def input_tzcodes_file(wilcards):
    from pathlib import Path
    if config["TIMEZONE"]["TYPE"] == "MULTIPLE":
        if not config["TIMEZONE"]["MULTIPLE"]["TZCODES_FILE"].lower().endswith(".csv"):
            raise ValueError("[TIMEZONE][MULTIPLE][TZCODES_FILE] should point to a CSV file, instead you typed: " + config["TIMEZONE"]["MULTIPLE"]["TZCODES_FILE"])
        if not Path(config["TIMEZONE"]["MULTIPLE"]["TZCODES_FILE"]).exists():
            raise ValueError("[TIMEZONE][MULTIPLE][TZCODES_FILE] should point to a CSV file, the file in the path you typed does not exist: " + config["TIMEZONE"]["MULTIPLE"]["TZCODES_FILE"])
        return [config["TIMEZONE"]["MULTIPLE"]["TZCODES_FILE"]]
    return []

def pull_empatica_data_input_with_mutation_scripts(wilcards):
    import yaml
    from pathlib import Path
    input = dict()
    empatica_stream = config["EMPATICA_DATA_STREAMS"]["USE"]

    input["participant_file"] = "data/external/participant_files/{pid}.yaml"
    input["rapids_schema_file"] = "src/data/streams/rapids_columns.yaml"
    input["stream_format"] = "src/data/streams/" + empatica_stream + "/format.yaml"

    if Path("src/data/streams/"+ empatica_stream + "/container.R").exists():
        input["stream_container"] = "src/data/streams/"+ empatica_stream + "/container.R"
    elif Path("src/data/streams/"+ empatica_stream + "/container.py").exists():
        input["stream_container"] = "src/data/streams/"+ empatica_stream + "/container.py"
    else:
        raise ValueError("The container script for {stream} is missing: src/data/streams/{stream}/container.[py|R]".format(stream=empatica_stream))

    schema = yaml.load(open(input.get("stream_format"), 'r'), Loader=yaml.FullLoader)
    sensor = ("empatica_" + wilcards.sensor).upper()
    if sensor not in schema:
        raise ValueError("{sensor} is not defined in the schema {schema}".format(sensor=sensor, schema=input.get("stream_format")))
    
    scripts = schema[sensor]["MUTATION_SCRIPTS"]
    if isinstance(scripts, list):
        for idx, script in enumerate(scripts):
            if not script.lower().endswith((".py", ".r")):
                raise ValueError("Mutate scripts can only be Python or R scripts (.py, .R).\n   Instead we got {script} in \n   [{sensor}] of {schema}".format(script=script, sensor=sensor, schema=input.get("stream_format")))
            input["mutationscript"+str(idx)] = script
    return input
