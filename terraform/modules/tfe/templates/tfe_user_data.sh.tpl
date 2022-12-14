#!/usr/bin/env bash
set -euo pipefail

determine_os_distro() {
  local os_distro_name=$(grep "^NAME=" /etc/os-release | cut -d"\"" -f2)

  case "$os_distro_name" in 
    "Amazon Linux"*)
      os_distro="amzn2"
      ;;
    "Ubuntu"*)
      os_distro="ubuntu"
      ;;
    "CentOS Linux"*)
      os_distro="centos"
      ;;
    "Red Hat"*)
      os_distro="rhel"
      ;;
    *)
      echo "[ERROR] '$os_distro_name' is an unsupported Linux OS distro."
      exit_script 1
  esac

  echo "$os_distro"
}

install_awscli() {
  if [[ -n "$(command -v aws)" ]]; then 
    echo "[INFO] Detected 'aws-cli' is already installed. Skipping."
  else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -qq awscliv2.zip
    ./aws/install
    rm -f ./awscliv2.zip && rm -rf ./aws
  fi
}

install_docker() {
  local os_distro="$1"
  
  if [[ -n "$(command -v docker)" ]]; then
    echo "[INFO] Detected 'docker' is already installed. Skipping."
  else
    if [[ "$os_distro" == "ubuntu" ]]; then
      # https://docs.docker.com/engine/install/ubuntu/
      echo "[INFO] Installing Docker for Ubuntu (Focal)."
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update -y
      apt-get install -y docker-ce=5:20.10.7~3-0~ubuntu-focal docker-ce-cli=5:20.10.7~3-0~ubuntu-focal containerd.io
    elif [[ "$os_distro" == "amzn2" ]]; then
      # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html
      echo "[INFO] Installing Docker for Amazon Linux 2."
      amazon-linux-extras enable docker
      yum install -y docker-20.10.7-3.amzn2
    elif [[ "$os_distro" == "centos" ]]; then
      # https://docs.docker.com/engine/install/centos/
      echo "[INFO] Installing Docker for CentOS."
      yum install -y yum-utils
      yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      yum install -y docker-ce-20.10.7-3.el7 docker-ce-cli-20.10.7-3.el7 containerd.io
    elif [[ "$os_distro" == "rhel" ]]; then
      # https://docs.docker.com/engine/install/rhel/ - currently broken
      echo "[ERROR] 'docker' must be installed as a prereq on RHEL. Exiting."
      exit_script 4
    fi
    systemctl enable --now docker.service
  fi
}

install_dependencies() {
  local airgap_install="$1"
  local os_distro="$2"
  local pkg_repos_reachable_with_airgap="$3"
  local install_docker_before="$4"

  if [[ "$airgap_install" == "true" ]] && [[ "$pkg_repos_reachable_with_airgap" == "false" ]]; then
    echo "[INFO] Checking if prereq software depedencies exist for 'airgap' install."
    if [[ -z "$(command -v jq)" ]]; then
      echo "[ERROR] 'jq' not detected on system. Ensure 'jq' is installed on image before running."
      exit_script 2
    fi
    if [[ -z "$(command -v unzip)" ]]; then
      echo "[ERROR] 'unzip' not detected on system. Ensure 'unzip' is installed on image before running."
      exit_script 3
    fi
    if [[ -z "$(command -v docker)" ]]; then
      echo "[ERROR] 'docker' was not detected on system. Ensure 'docker' is installed on image before running."
      exit_script 4
    fi
    if [[ -z "$(command -v aws)" ]]; then
      echo "[ERROR] 'aws-cli' not detected on system. Ensure 'aws-cli' is installed on image before running."
      exit_script 5
    fi
  else
    echo "[INFO] Preparing to install prereq software dependecies."
    if [[ "$os_distro" == "ubuntu" ]]; then
      echo "[INFO] Installing software dependencies for Ubuntu."
      apt-get update -y
      apt-get install -y jq unzip
    elif [[ "$os_distro" == "amzn2" ]]; then 
      echo "[INFO] Installing software dependencies for Amazon Linux 2."
      yum update -y
      yum install -y jq unzip
    elif [[ "$os_distro" == "centos" ]]; then 
      echo "[INFO] Installing software dependencies for CentOS."
      yum install -y epel-release
      yum update -y
      yum install -y jq unzip
    elif [[ "$os_distro" == "rhel" ]]; then 
      echo "[INFO] Installing software dependencies for RHEL."
      yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
      yum update -y
      yum install -y jq unzip
    fi
    if [[ "$install_docker_before" == "true" ]] || [[ "$airgap_install" == "true" ]]; then
      install_docker "$os_distro"
    fi
    install_awscli
  fi
}

retrieve_obj_from_s3() {
  local src="$1"
  local dst="$2"

  if [[ "$src" == "" ]]; then
    echo "[ERROR] Did not detect a valid path."
    exit_script 10
  else
    echo "[INFO] Copying $src to $dst..."
    aws s3 cp "$src" "$dst"
  fi
}

retrieve_tfe_cert() {
  echo "[INFO] Retrieving TFE TLS/SSL certificate from ${tfe_cert_secret_arn}."
  TFE_CERT=$(aws secretsmanager get-secret-value --region $REGION --secret-id ${tfe_cert_secret_arn} --query SecretString --output text)
  echo "$TFE_CERT" > $TFE_CONFIG_DIR/cert.pem
}

retrieve_tfe_privkey() {
  echo "[INFO] Retrieving TFE TLS/SSL private key from ${tfe_privkey_secret_arn}."
  TFE_PRIVKEY=$(aws secretsmanager get-secret-value --region $REGION --secret-id ${tfe_privkey_secret_arn} --query SecretString --output text)
  echo "$TFE_PRIVKEY" | base64 -d > $TFE_CONFIG_DIR/privkey.pem
}

retrieve_ca_bundle() {
  CA_CERTS=$(aws secretsmanager get-secret-value --region $REGION --secret-id ${ca_bundle_secret_arn} --query SecretString --output text)
  echo "$CA_CERTS"
}

retrieve_install_secret() {
  local sec_key="$1"
  local sec_value="$2"
  local sec_region="$3"
  local sec_arn="$4"

  if [[ "$sec_value" == "aws_secretsmanager" ]]; then
    if [[ "$sec_arn" == "" ]]; then
      echo "[ERROR] 'tfe_install_secrets_arn' was not set."
      exit_script 20
    else
      SECRET=$(aws secretsmanager get-secret-value --region $sec_region --secret-id $sec_arn --query SecretString --output text | jq -r .$sec_key)
    fi
  else
    SECRET=$sec_value
  fi

  echo "$SECRET"
}

configure_log_forwarding() {
  echo "INFO: Configuring Fluent Bit log forwarding"
  cat > "$TFE_CONFIG_DIR/fluent-bit.conf" << EOF
${fluent_bit_config}
EOF


  LOG_FORWARDING_CONFIG=$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' $TFE_CONFIG_DIR/fluent-bit.conf)
}

docker_pull_from_ecr() {
  aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${custom_tbw_ecr_repo_uri}
  docker pull ${custom_image_tag}
}

exit_script() { 
  if [[ "$1" == 0 ]]; then
    echo "[INFO] TFE user_data script finished successfully!"
  else
    echo "[ERROR] TFE user_data script finished with error code $1."
  fi
  
  exit "$1"
}

main() {
  echo "[INFO] Beginning TFE user_data script."
  os_distro_result=$(determine_os_distro)
  echo "[INFO] Detected OS distro is '$os_distro_result'."
  install_dependencies "${airgap_install}" "$os_distro_result" "${pkg_repos_reachable_with_airgap}" "${install_docker_before}"

  REGION=${s3_app_bucket_region}
  IMDS_V2_TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60"`
  EC2_PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_V2_TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
  TFE_INSTALLER_DIR="/opt/tfe/installer"
  TFE_CONFIG_DIR="/etc"
  TFE_SETTINGS_PATH="$TFE_CONFIG_DIR/tfe-settings.json"
  TFE_LICENSE_PATH="$TFE_CONFIG_DIR/license.rli"
  TFE_AIRGAP_PATH="$TFE_INSTALLER_DIR/tfe-bundle.airgap"
  REPL_BUNDLE_PATH="$TFE_INSTALLER_DIR/replicated.tar.gz"
  REPL_CONF_PATH="$TFE_CONFIG_DIR/replicated.conf"
  
  mkdir -p $TFE_INSTALLER_DIR
  
  retrieve_obj_from_s3 "${tfe_license_filepath}" "$TFE_LICENSE_PATH"

  if [[ "${airgap_install}" == "true" ]]; then
    # retrieve TFE install files from bootstrap bucket for 'airgap' install
    retrieve_obj_from_s3 "${tfe_airgap_bundle_path}" "$TFE_AIRGAP_PATH"
    retrieve_obj_from_s3 "${replicated_bundle_path}" "$REPL_BUNDLE_PATH"
  else
    # retrieve 'install.sh' script for 'online' install
    echo "[INFO] Retrieving TFE install script directly from Replicated."
    curl https://install.terraform.io/ptfe/stable -o "$TFE_INSTALLER_DIR/install.sh"
  fi
    
  # optionally retrieve certs
  if [[ "${tfe_cert_secret_arn}" != "" ]]; then
    retrieve_tfe_cert
  fi
  
  if [[ "${tfe_privkey_secret_arn}" != "" ]]; then
    retrieve_tfe_privkey
  fi

  if [[ "${ca_bundle_secret_arn}" != "" ]]; then
    echo "[INFO] Retrieving custom CA bundle from ${ca_bundle_secret_arn}."
    CA_CERTS=$(retrieve_ca_bundle)
  else
    CA_CERTS=""
  fi

  # retrieve install secrets
  echo "[INFO] Retrieving install secret 'console_password'."
  CONSOLE_PASSWORD=$(retrieve_install_secret "console_password" "${console_password}" "$REGION" "${tfe_install_secrets_arn}")
  echo "[INFO] Retrieving install secret 'enc_password'."
  ENC_PASSWORD=$(retrieve_install_secret "enc_password" "${enc_password}" "$REGION" "${tfe_install_secrets_arn}")
 
  # enable & configure log forwarding with Fluent Bit
  # https://www.terraform.io/docs/enterprise/admin/logging.html#enable-log-forwarding
  if [[ "${log_forwarding_enabled}" == "1" ]]; then
    configure_log_forwarding
  else
    LOG_FORWARDING_CONFIG=""
  fi
  
  # generate Replicated config file
  # https://help.replicated.com/docs/native/customer-installations/automating/
  echo "[INFO] Generating $REPL_CONF_PATH file."
  cat > $REPL_CONF_PATH << EOF
{
  "DaemonAuthenticationType": "password",
  "DaemonAuthenticationPassword": "$CONSOLE_PASSWORD",
  "ImportSettingsFrom": "$TFE_SETTINGS_PATH",
%{ if airgap_install == true ~}
  "LicenseBootstrapAirgapPackagePath": "$TFE_AIRGAP_PATH",
%{ else ~}
  "ReleaseSequence": ${tfe_release_sequence},
%{ endif ~}
  "LicenseFileLocation": "$TFE_LICENSE_PATH",
  "TlsBootstrapHostname": "${tfe_hostname}",
  "TlsBootstrapType": "${tls_bootstrap_type}",
%{ if tls_bootstrap_type == "server-path" ~}
  "TlsBootstrapCert": "$TFE_CONFIG_DIR/cert.pem",
  "TlsBootstrapKey": "$TFE_CONFIG_DIR/privkey.pem",
%{ endif ~}
  "RemoveImportSettingsFrom": ${remove_import_settings_from},
  "BypassPreflightChecks": true
}
EOF

  # generate TFE app settings JSON file
  # https://www.terraform.io/docs/enterprise/install/automating-the-installer.html#available-settings
  echo "[INFO] Generating $TFE_SETTINGS_PATH file."
  cat > $TFE_SETTINGS_PATH << EOF
{
  "aws_access_key_id": {},
  "aws_instance_profile": {
      "value": "1"
  },
  "aws_secret_access_key": {},
  "azure_account_key": {},
  "azure_account_name": {},
  "azure_container": {},
  "azure_endpoint": {},
  "backup_token": {},
  "ca_certs": {
    "value": "$CA_CERTS"
  },
  "capacity_concurrency": {
      "value": "${capacity_concurrency}"
  },
  "capacity_cpus": {},
  "capacity_memory": {
      "value": "${capacity_memory}"
  },
  "custom_image_tag": {
    "value": "${custom_image_tag}"
  },
  "disk_path": {},
  "enable_active_active": {
    "value": "${enable_active_active}"
  },
  "enable_metrics_collection": {
      "value": "${enable_metrics_collection}"
  },
  "enc_password": {
      "value": "$ENC_PASSWORD"
  },
  "extern_vault_addr": {},
  "extern_vault_enable": {
      "value": "0"
  },
  "extern_vault_path": {},
  "extern_vault_propagate": {},
  "extern_vault_role_id": {},
  "extern_vault_secret_id": {},
  "extern_vault_token_renew": {},
  "extra_no_proxy": {
    "value": "${extra_no_proxy}"
  },
  "force_tls": {
    "value": "${force_tls}"
  },
  "gcs_bucket": {},
  "gcs_credentials": {},
  "gcs_project": {},
  "hairpin_addressing": {
    "value": "${hairpin_addressing}"
  },
  "hostname": {
      "value": "${tfe_hostname}"
  },
  "iact_subnet_list": {},
  "iact_subnet_time_limit": {
      "value": "60"
  },
  "installation_type": {
      "value": "production"
  },
  "log_forwarding_config": {
    "value": "$LOG_FORWARDING_CONFIG"
  },
  "log_forwarding_enabled": {
    "value": "${log_forwarding_enabled}"
  },
  "metrics_endpoint_enabled": {
      "value": "${metrics_endpoint_enabled}"
  },
  "metrics_endpoint_port_http": {
      "value": "${metrics_endpoint_port_http}"
  },
  "metrics_endpoint_port_https": {
      "value": "${metrics_endpoint_port_https}"
  },
  "pg_dbname": {
      "value": "${pg_dbname}"
  },
  "pg_extra_params": {
      "value": "sslmode=require"
  },
  "pg_netloc": {
      "value": "${pg_netloc}"
  },
  "pg_password": {
      "value": "${pg_password}"
  },
  "pg_user": {
      "value": "${pg_user}"
  },
  "placement": {
      "value": "placement_s3"
  },
  "production_type": {
      "value": "external"
  },
  "redis_host": {
    "value": "${redis_host}"
  },
  "redis_pass": {
    "value": "${redis_pass}"
  },
  "redis_port": {
    "value": "${redis_port}"
  },
  "redis_use_password_auth": {
    "value": "${redis_use_password_auth}"
  },
  "redis_use_tls": {
    "value": "${redis_use_tls}"
  },
  "restrict_worker_metadata_access": {
    "value": "${restrict_worker_metadata_access}"
  },
  "s3_bucket": {
      "value": "${s3_app_bucket_name}"
  },
  "s3_endpoint": {},
  "s3_region": {
      "value": "${s3_app_bucket_region}"
  },
%{ if kms_key_arn != "" ~}
  "s3_sse": {
      "value": "aws:kms"
  },
  "s3_sse_kms_key_id": {
      "value": "${kms_key_arn}"
  },
%{ else ~}
  "s3_sse": {},
  "s3_sse_kms_key_id": {},
%{ endif ~}
  "tbw_image": {
      "value": "${tbw_image}"
  },
  "tls_ciphers": {},
  "tls_vers": {
      "value": "tls_1_2_tls_1_3"
  }
}
EOF

  # execute the TFE installer script
  cd $TFE_INSTALLER_DIR
  if [[ "${airgap_install}" == "true" ]]; then
    echo "[INFO] Extracting Replicated tarball for 'airgap' install."
    tar xzf $REPL_BUNDLE_PATH -C $TFE_INSTALLER_DIR
    echo "[INFO] Executing TFE install in 'airgap' mode."
  else
    echo "[INFO] Executing TFE install in 'online' mode."
  fi

  bash ./install.sh \
%{ if airgap_install == true ~}
    airgap \
%{ endif ~}
%{ if http_proxy != "" ~}
    http-proxy=${http_proxy} \
%{ else ~}
    no-proxy \
%{ endif ~}
%{ if extra_no_proxy != "" ~}
    additional-no-proxy=${extra_no_proxy} \
%{ endif ~}
%{ if enable_active_active == 1 ~}
    disable-replicated-ui \
%{ endif ~}
%{ if install_docker_before == true ~}
    no-docker \
%{ endif ~}
    private-address=$EC2_PRIVATE_IP \
    public-address=$EC2_PRIVATE_IP

  # docker pull custom tbw image if a custom image tag was provided
  if [[ ${tbw_image} == "custom_image" && ${custom_image_tag} != "hashicorp/build-worker:now" ]]; then
    echo "[INFO] Detected custom TBW image was specified. Attempting to docker pull ${custom_image_tag}."
    docker_pull_from_ecr
  fi

  echo "[INFO] Sleeping for a minute while TFE initializes."
  sleep 60

  echo "[INFO] Polling TFE health check endpoint until app becomes ready..."
  while ! curl -ksfS --connect-timeout 5 https://$EC2_PRIVATE_IP/_health_check; do
    sleep 5
  done

  exit_script 0
}

main "$@"