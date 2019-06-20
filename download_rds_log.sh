#!/bin/bash

# brew update
# brew upgrade
# brew install awscli
# brew install fzf

function getInstanceId() {
  aws rds describe-db-instances \
      --output text \
      --query 'DBInstances[*].[DBInstanceIdentifier] | sort_by(@, &[0])'
}

function getFileNames() {
  local instanceId=$1
  aws rds describe-db-log-files \
      --output text \
      --db-instance-identifier $instanceId \
      --query 'DescribeDBLogFiles[*].[LogFileName]' | sort -r
}

function downloadLog() {
  local instanceId=$1
  local filename=$2

  aws rds download-db-log-file-portion \
    --output text \
    --db-instance-identifier $instanceId \
    --log-file-name $filename \
     --no-paginate
}

instanceId=$(getInstanceId | fzf | awk '{print $1}')
if [ ! -n "$instanceId" ]; then
  echo "You must select at least one instanceId."
  exit 1
else
  prefix=error/postgresql.log.
  filenames=$(getFileNames $instanceId | fzf -m | awk '{print $1}')
  if [ ! -n "$filenames" ]; then
    echo "You must select at least one filename."
  else
    echo "Selected instanceId: $instanceId"
    for filename in $filenames; do
      echo "Downloading ${filename}..."
      downloadLog $instanceId $filename > $instanceId.${filename#$prefix}.log
    done
  fi
fi
