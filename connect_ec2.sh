#!/bin/bash

# brew update
# brew upgrade
# brew install awscli
# brew install fzf

function trim() {
  awk 'BEGIN{FS=OFS="\t"}{gsub(/^[ \t]+/,"",$1);gsub(/[ \t]+$/,"",$1)}1'
}

function getEc2Instance() {
  aws ec2 describe-instances \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'] | [0].Value, PrivateIpAddress, KeyName, State.Name]" \
    --output text | \
    awk -v OFS='\t' '{print $3, $2, $4, $1}' | \
    sort -k4
}

instance=$(getEc2Instance | fzf | head -1)

if [ ! -n "$instance" ]; then
  echo "You must select at least one instance."
  exit 1
else
  instanceName=$(awk 'BEGIN {OFS="\t";} {print $3}' <<< "$instance" | trim)
  keyName=$(awk 'BEGIN {OFS="\t";} {print $1}' <<< "$instance" | trim)
  privateIpAddress=$(awk 'BEGIN {OFS="\t";} {print $2}' <<< "$instance" | trim)

  if [ ! -f "$keyName.pem" ]; then
    while true; do
      read -p "Please enter your the $keyName.pem path: " keyFile
      if [ -f "$keyFile" ]; then
        break;
      else
      	echo "$keyFile not found or bad permissions."
      fi
    done
  else
    keyFile="$keyName.pem"
  fi

  echo "Connecting to $instanceName with $keyFile..."
  ssh -i "$keyFile" ubuntu@$privateIpAddress
fi
