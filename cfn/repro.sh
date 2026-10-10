#!/usr/bin/env bash
# CloudFormation-only repro: DescribeChangeSet with IncludePropertyValues omits
# a resource whose JSON string property only gains a key.
set -euo pipefail
cd "$(dirname "$0")"

STACK=cfn-diff-repro
CS=add-key

aws cloudformation deploy --stack-name "$STACK" --template-file v1.yaml
aws cloudformation create-change-set --stack-name "$STACK" --change-set-name "$CS" \
  --template-body file://v2.yaml >/dev/null
aws cloudformation wait change-set-create-complete --stack-name "$STACK" --change-set-name "$CS"

for flag in --no-include-property-values --include-property-values; do
  echo "## describe-change-set $flag"
  aws cloudformation describe-change-set --stack-name "$STACK" --change-set-name "$CS" "$flag" \
    --query 'Changes[].ResourceChange.[Action,LogicalResourceId]' --output text
done

aws cloudformation delete-change-set --stack-name "$STACK" --change-set-name "$CS"
aws cloudformation delete-stack --stack-name "$STACK"
aws cloudformation wait stack-delete-complete --stack-name "$STACK"
