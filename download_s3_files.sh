#!/bin/bash

# brew update
# brew upgrade
# brew install awscli
# brew install fzf

bucket=$(aws s3 ls | sort -rk1 | fzf | awk '{print $3}')
if [ ! -n "$bucket" ]; then
  echo "You must select at least one bucket."
  exit 1
else
  files=$(aws s3 ls "s3://$bucket" --recursive --human-readable --summarize | sort -rk1 | fzf -m | awk '{print $0}')
  if [ ! -n "$files" ]; then
    echo "Select at least one file."
    exit 1
  fi

  mkdir -p files
  aws s3 cp "s3://$bucket" ./files --recursive

  echo "From s3://$bucket"
  for file in $files; do
    echo "[Download] $file"
  done

  echo "Check files directory."
fi
