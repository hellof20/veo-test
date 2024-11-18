#!/bin/bash

mimeType="image/png"
aspect_ratio="16:9"
output="gs://pwm-lowa/veo-outputs"
token=$(gcloud auth print-access-token)

while IFS=, read -r image prompt; do

    for i in {1..4}; do
        seed=$((RANDOM % 100 + 1))
        data="{\"instances\": [{\"prompt\": \"$prompts\",\"image\": {\"gcsUri\": \"$image\", \"mimeType\": \"$mimeType\"}}],\"parameters\": {\"storageUri\": \"$output\",\"seed\": $seed,\"aspectRatio\": \"$aspect_ratio\"}}"
        result=$(curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" https://us-central1-aiplatform.googleapis.com/v1beta1/projects/veo-testing/locations/us-central1/publishers/google/models/veo-001-preview-0815:predictLongRunning -d "$data")
        echo $result
        operation_name=$(echo $result | jq -r .name)
        operation_id=$(echo $operation_name | sed 's/.*\///')
        echo $operation_id,$image,$seed >> data/batch_operation.csv
    done
    sleep 12
done  < data/bilibili_veo_test_10.csv

