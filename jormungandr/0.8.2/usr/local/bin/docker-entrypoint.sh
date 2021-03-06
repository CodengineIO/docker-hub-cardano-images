#!/usr/bin/env bash
set -e
JORMUNGAND_USER_HOME=$HOME
GENESIS_HASH_FILE=${JORMUNGAND_USER_HOME}etc/genesis-hash.txt
NODE_CONFIG_FILE=${JORMUNGAND_USER_HOME}etc/node_config.yaml
NODE_SECRET_FILE=${JORMUNGAND_USER_HOME}etc/secrets/node_secret.yaml

function setPublicIPvariable () {
  case $1 in
    IPv4)
      if PUBLIC_IPV4=$(curl --proto '=https' --tlsv1.2 -sSf --ipv4 https://ifconfig.co/); then
        export PUBLIC_IPV4=${PUBLIC_IPV4}
      fi
    ;;
    IPv6)
      if PUBLIC_IPV6=$(curl --proto '=https' --tlsv1.2 -sSf --ipv6 https://ifconfig.co/); then
        export PUBLIC_IPV6=${PUBLIC_IPV6}
      fi
    ;;
    all)
      setPublicIPvariable IPv4
      setPublicIPvariable IPv6
  esac
}

if [[ -z ${PUBLIC_IPV4} ]]; then
  counter=1
  while [[ -z ${PUBLIC_IPV4} ]] && [[ $counter -lt 10 ]]; do
    echo 'Public IPv4 IP address not set! Trying again... (' $counter '/10)'
    setPublicIPvariable "IPv4"
    let "counter++"
    if [[ -z ${PUBLIC_IPV4} ]] && [[ $counter -eq 10 ]]; then
      echo "Failed to obtain public IPv4; exiting..."
      exit
    fi
  done
fi

if [[ -z ${PUBLIC_IPV6} ]]; then
  counter=1
  while [[ -z ${PUBLIC_IPV6} ]] && [[ $counter -lt 10 ]]; do
    echo 'Public IPv6 IP address not set! Trying again... (' $counter '/10)'
    setPublicIPvariable "IPv6"
    let "counter++"
    if [[ -z ${PUBLIC_IPV6} ]] && [[ $counter -eq 10 ]]; then
      echo "Failed to obtain public IPv6; continuing..."
    fi
  done
fi

if [[ -z ${PUBLIC_IPV4} ]]; then
  PUBLIC_IPV4="NOT SET; unable to be a slot leader!"
fi

if [[ -z ${PUBLIC_IPV6} ]]; then
  PUBLIC_IPV6="NOT SET."
fi

echo 'Public IPv4 address is:' ${PUBLIC_IPV4}
echo 'Public IPv6 address is:' ${PUBLIC_IPV6}

if [[ ! -f ${GENESIS_HASH_FILE} ]]; then
  echo 'Genesis hash file does not exists! Jormungandr can NOT start!!!'
  exit
else
  GENESIS_HASH=$(cat ${GENESIS_HASH_FILE})
  echo "Genesis hash set to ${GENESIS_HASH}!"
fi

if [[ ! -f ${NODE_CONFIG_FILE} ]]; then
  echo 'Jormungandr node config file does not exists! Jormungandr can NOT start!!!'
  exit
else
  if [[ -f ${NODE_SECRET_FILE} ]]; then
    echo 'Jormungand node secret file found! Jormungandr will start as a slot leader!'
    jormungandr \
      --genesis-block-hash ${GENESIS_HASH} \
      --config ${NODE_CONFIG_FILE} \
      --secret ${NODE_SECRET_FILE}
  else
    jormungandr \
      --genesis-block-hash ${GENESIS_HASH} \
      --config ${NODE_CONFIG_FILE}
  fi
fi

exec "$@"