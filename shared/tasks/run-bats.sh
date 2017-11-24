#!/usr/bin/env bash

set -e

: ${INFRASTRUCTURE:?}
: ${STEMCELL_NAME:?}
: ${BAT_INFRASTRUCTURE:?}
: ${BAT_NETWORKING:?}
: ${BAT_RSPEC_FLAGS:?}

source pipelines/shared/utils.sh
source /etc/profile.d/chruby.sh
chruby 2.1.7

metadata="$( cat environment/metadata )"
mkdir -p bats-config
bosh2 int pipelines/${INFRASTRUCTURE}/assets/bats/bats-spec.yml \
  -v "stemcell_name=${STEMCELL_NAME}" \
  -l environment/metadata > bats-config/bats-config.yml

source director-state/director.env
export BAT_PRIVATE_KEY="$( creds_path /jumpbox_ssh/private_key )"
export BAT_DNS_HOST="${BOSH_ENVIRONMENT}"
export BAT_STEMCELL=$(realpath stemcell/*.tgz)
export BAT_DEPLOYMENT_SPEC=$(realpath bats-config/bats-config.yml)
export BAT_BOSH_CLI=$(which bosh2)

ssh_key_path=/tmp/bat_private_key
echo "$BAT_PRIVATE_KEY" > $ssh_key_path
chmod 600 $ssh_key_path
export BOSH_GW_PRIVATE_KEY=$ssh_key_path

pushd bats
  # mock: alicloud does not support disk size less than 20GB
  if [${${INFRASTRUCTURE}} == "alicloud"]
    sed -ig "s/2048/20480/" ./spec/system/with_release_stemcell_spec.rb
    sed -ig "s/4096/40960/" ./spec/system/with_release_stemcell_spec.rb
  fi
  bundle install
  bundle exec rspec spec $BAT_RSPEC_FLAGS
popd
