#!/bin/bash

# Run the causal inference workflow using Nextflow

echo "Running Causal Inference Workflow with Nextflow..."

## Check if Docker image exists
#if ! docker images causal-inference:latest | grep -q causal-inference; then
#    echo "Docker image not found. Building image first..."
#    ./build_docker.sh
#fi

# Clean previous results
rm -rf results work .nextflow*

# Run Nextflow workflow
nextflow run main.nf \
    -profile docker \
    --outdir results \
    -with-report results/nextflow_report.html \
    -with-timeline results/nextflow_timeline.html \
    -with-dag results/nextflow_dag.html

if [ $? -eq 0 ]; then
    echo ""
    echo "Workflow completed successfully!"
    echo "Results are available in the 'results' directory"
    echo ""
    echo "Generated files:"
    find results -type f -name "*.png" -o -name "*.csv" -o -name "*.txt" | sort
else
    echo "Workflow failed!"
    exit 1
fi
