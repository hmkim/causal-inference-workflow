#!/bin/bash

# Deploy Causal Inference Workflow to AWS HealthOmics
# Make sure you have AWS CLI configured and appropriate permissions

# Configuration variables
BUCKET_NAME="${BUCKET_NAME:-your-bucket-name}"  # Can be overridden by environment variable
WORKFLOW_NAME="causal-inference-workflow"
WORKFLOW_DESCRIPTION="R-based causal inference workflow with propensity score matching"
REGION="${AWS_REGION:-us-east-1}"

# Check if bucket name is provided
if [ "$BUCKET_NAME" = "your-bucket-name" ]; then
    echo "Error: Please set BUCKET_NAME environment variable or modify the script"
    echo "Usage: BUCKET_NAME=my-bucket-name ./deploy_to_healthomics.sh"
    exit 1
fi

echo "Using S3 bucket: $BUCKET_NAME"
echo "Using AWS region: $REGION"

# Step 1: Create workflow package from nf_workflow directory
echo "Creating workflow package from nf_workflow directory..."
cd nf_workflow
zip -r ../workflow_package.zip .
cd ..

if [ ! -f "workflow_package.zip" ]; then
    echo "Error: Failed to create workflow_package.zip"
    exit 1
fi

echo "✓ Created workflow_package.zip"

# Step 2: Upload workflow package to S3
echo "Uploading workflow package to S3..."
aws s3 cp workflow_package.zip s3://$BUCKET_NAME/workflows/workflow_package.zip --region $REGION

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload workflow package to S3"
    exit 1
fi

echo "✓ Uploaded workflow_package.zip to s3://$BUCKET_NAME/workflows/"

# Step 3: Create HealthOmics workflow
echo "Creating HealthOmics workflow: $WORKFLOW_NAME"

aws omics create-workflow \
  --name $WORKFLOW_NAME \
  --description "$WORKFLOW_DESCRIPTION" \
  --definition-uri s3://$BUCKET_NAME/workflows/workflow_package.zip \
  --parameter-template file://parameter_template.json \
  --engine NEXTFLOW \
  --region $REGION

if [ $? -eq 0 ]; then
    echo "✓ Successfully created HealthOmics workflow: $WORKFLOW_NAME"
    echo "✓ Workflow definition URI: s3://$BUCKET_NAME/workflows/workflow_package.zip"
else
    echo "Error: Failed to create HealthOmics workflow"
    exit 1
fi

