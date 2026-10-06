#!/usr/bin/env bash
set -euo pipefail

: "${SF_CLIENT_ID:?SF_CLIENT_ID is required}"
: "${SF_USERNAME:?SF_USERNAME is required}"
: "${SF_INSTANCE_URL:?SF_INSTANCE_URL is required}"
: "${SF_JWT_KEY_FILE:?SF_JWT_KEY_FILE is required}"

SF_ALIAS="${SF_ALIAS:-target-org}"

sf org login jwt \
  --client-id "$SF_CLIENT_ID" \
  --jwt-key-file "$SF_JWT_KEY_FILE" \
  --username "$SF_USERNAME" \
  --instance-url "$SF_INSTANCE_URL" \
  --alias "$SF_ALIAS"

sf org display --target-org "$SF_ALIAS"
