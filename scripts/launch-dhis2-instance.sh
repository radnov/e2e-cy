#!/usr/bin/env bash

set -euxo pipefail

instance_name="$1"
group_name="$2"
instance_version="$3"

# 1 day
ttl=$(($EPOCHSECONDS + 86400))

versions_json="https://releases.dhis2.org/v1/versions/stable.json"

default_dhis2_credentials="admin:district"


latest_patch_version=$(
  curl -fsSL "$versions_json" |
  jq -r --arg version "$instance_version" '.versions[] | select(.name == $version ) | .latestPatchVersion'
)

tag="$instance_version.$latest_patch_version"

token=$($HTTP --auth "$USER_EMAIL:$PASSWORD" post "$INSTANCE_HOST/tokens" | jq -r '.access_token')

curl "https://raw.githubusercontent.com/dhis2-sre/im-manager/master/scripts/deploy-dhis2.sh" -O
chmod +x deploy-dhis2.sh
IMAGE_TAG="$tag" INSTANCE_TTL="$ttl" DB_ID=1 ACCESS_TOKEN="$token" ./deploy-dhis2.sh "$group_name" "$instance_name"

echo "Instance $instance_name deployed!"

instance_response() {
  $HTTP --follow --headers get "$INSTANCE_DOMAIN/$instance_name" | head -1 | cut -d ' ' -f 2
}

until [[ "$(instance_response)" == "200" ]]
do
  echo "Instance not ready yet ..."
  sleep 30
done

echo "Instance is ready! Triggering Analytics generation ..."

analytics_status_endpoint=$(
  $HTTP --auth "$default_dhis2_credentials" post "$INSTANCE_DOMAIN/$instance_name/api/resourceTables/analytics" |
  jq -r '.response .relativeNotifierEndpoint'
)

analytics_status() {
  $HTTP --auth "$default_dhis2_credentials" get "$INSTANCE_DOMAIN/${instance_name}${analytics_status_endpoint}" |
  jq -r '.[] .completed'
}

until [[ "$(analytics_status)" =~ "true" ]]
do
  echo "Analytics tasks haven't completed yet ..."
  sleep 30
done

echo "Analytics tasks have completed!"
