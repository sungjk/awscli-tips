#!/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 2 ] || die "Usage: cloudsearch-clone-domain <domain> <newdomain>"

aws cloudsearch describe-index-fields \
  --domain $1 \
  --output json | \
  jq ".[][] | {\"DomainName\": \"$2\", \"IndexField\": .Options} | tostring" | \
  sed 's/^/aws cloudsearch define-index-field --cli-input-json /' > \
  define-fields-$2.sh

chmod +x define-fields-$2.sh

echo "Create a cloudsearch domain '$2' from '$1'"

aws cloudsearch create-domain --domain-name $2
./define-fields-$2.sh
