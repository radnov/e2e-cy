#!/usr/bin/env bash

set -euo pipefail

instance_name="$1"
group_name="$2"
instance_version="$3"

# 1 day
ttl=86400

db_id=1
db_size=30Gi

stack_name=dhis2

versions_json="https://releases.dhis2.org/v1/versions/stable.json"

latest_patch_version=$(
  curl -fsSL "$versions_json" |
  jq -r --arg version "$instance_version" '.versions[] | select(.name == $version ) | .latestPatchVersion'
)

default_tag="$instance_version.$latest_patch_version"
tag=${DHIS2_IMAGE_TAG:-$default_tag}

ACCESS_TOKEN=$($HTTP --auth "$USER_EMAIL:$PASSWORD" post "$INSTANCE_HOST/tokens" | jq -r '.access_token')

instance_id=$(
  echo "{
    \"name\": \"$instance_name\",
    \"groupName\": \"$group_name\",
    \"stackName\": \"$stack_name\"
  }" | $HTTP post "$INSTANCE_HOST/instances" "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.ID'
)

echo "{
  \"name\": \"$instance_name\",
  \"groupName\": \"$group_name\",
  \"stackName\": \"$stack_name\",
  \"optionalParameters\": [
    {
      \"name\": \"IMAGE_TAG\",
      \"value\": \"$tag\"
    },
    {
      \"name\": \"DATABASE_SIZE\",
      \"value\": \"$db_size\"
    }
  ],
  \"requiredParameters\": [
    {
      \"name\": \"DATABASE_ID\",
      \"value\": \"$db_id\"
    }
  ]
}" | $HTTP post "$INSTANCE_HOST/instances/$instance_id/deploy" "Authorization: Bearer $ACCESS_TOKEN"

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
  $HTTP --auth "admin:district" post "$INSTANCE_DOMAIN/$instance_name/api/resourceTables/analytics" |
  jq -r '.response .relativeNotifierEndpoint'
)

analytics_status() {
  $HTTP --auth "admin:district" get "$INSTANCE_DOMAIN/${instance_name}${analytics_status_endpoint}" |
  jq -r '.[] .completed'
}

until [[ "$(analytics_status)" =~ "true" ]]
do
  echo "Analytics tasks haven't completed yet ..."
  sleep 30
done

echo "Analytics tasks have completed!"
