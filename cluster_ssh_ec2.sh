#!/bin/bash

# brew update
# brew upgrade
# brew install awscli
# brew install fzf
# gem install i2cssh

# ipAddrs=$(aws ec2 describe-instances \
#   --query "Reservations[].Instances[].{ group: Tags[?Key=='Group'] | [0].Value, keyName: KeyName, ipAddr: PrivateIpAddress }" \
#   --output json | \
#   jq -c 'map(select(.group != null)) | group_by(.group)[] | {(.[0].group): [.[] | .ipAddr]}' | \
#   jq -j 'keys[] as $k | "\($k)", "\(.[$k][]? | " ", .)", "\n"' | \
#   fzf | \
#   awk '{print substr($0, index($0, $2))}')
#
# [ ! -z "$ipAddrs" ] || die "You must select a group."
#
# for ipAddr in $ipAddrs
# do
#  host="ubuntu@$ipAddr"
#  hosts="$hosts $host"
# done
#
# read -p "Please enter your .pem file: " pemFile
#
# if [ -f "$pemFile" ]; then
#   echo "Connecting to '$hosts' with '$pemFile'..."
#   i2cssh -b -Xi="$pemFile" $hosts
# else
#   echo "'$pemFile' not found or bad permissions."
# fi

function trim() {
  awk 'BEGIN{FS=OFS="\t"}{gsub(/^[ \t]+/,"",$1);gsub(/[ \t]+$/,"",$1)}1'
}

function getEc2Instance() {
  aws ec2 describe-instances \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'] | [0].Value, PrivateIpAddress, KeyName]" \
    --output text | \
    awk -v OFS='\t' '{print $3, $2, $1}' | \
    sort -k3
}

instance=$(getEc2Instance | fzf -m)

echo $instance

if [ ! -n "$instance" ]; then
  echo "You must select at least one instance."
  exit 1
else
  instanceName=$(awk 'BEGIN {OFS="\t";} {print $3}' <<< "$instance" | trim)
  publicDnsName=$(awk 'BEGIN {OFS="\t";} {printf("ubuntu@%s\n", $2)}' <<< "$instance" | trim)
  keyName=$(awk 'BEGIN {OFS="\t";} {print $1}' <<< "$instance" | head -1 | trim)

  if [ ! -f "$HOME/.ssh/$keyName.pem" ]; then
    while true; do
      read -p "Please enter your the $keyName.pem path: " keyFile
      if [ -f "$keyFile" ]; then
        break;
      else
          echo "$keyFile not found or bad permissions."
      fi
    done
  else
    keyFile="$HOME/.ssh/$keyName.pem"
  fi

  echo "Connecting to $instanceName with $keyFile..."
  i2cssh -b -Xi="$keyFile" $publicDnsName
fi
