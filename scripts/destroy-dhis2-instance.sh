#!/usr/bin/env bash

set -euxo pipefail

instance_name="$1"
group_name="$2"

ACCESS_TOKEN=$($HTTP --auth "$USER_EMAIL:$PASSWORD" post "$INSTANCE_HOST/tokens" | jq -r '.access_token')

instance_id=$($HTTP get "$INSTANCE_HOST/instances-name-to-id/$group_name/$instance_name" "Authorization: Bearer $ACCESS_TOKEN")

$HTTP delete "$INSTANCE_HOST/instances/$instance_id" "Authorization: Bearer $ACCESS_TOKEN"
