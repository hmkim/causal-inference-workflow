#!/bin/bash

# Deploy Causal Inference Workflow to AWS HealthOmics
# Make sure you have AWS CLI configured and appropriate permissions

WORKFLOW_NAME="causal-inference-workflow"
WORKFLOW_DESCRIPTION="R-based causal inference workflow with propensity score matching"

echo "Creating HealthOmics workflow: $WORKFLOW_NAME"

# The base64 workflow package is ready - you can use it with the AWS CLI
aws omics create-workflow \
  --name $WORKFLOW_NAME \
  --description "$WORKFLOW_DESCRIPTION" \
  --definition-uri s3://{your-bucket-name}/workflow_package.zip \
  --parameter-template file://parameter_template.json \
  --engine NEXTFLOW \
  --region us-east-1

