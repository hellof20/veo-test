#!/bin/bash

token=$(gcloud auth print-access-token)

while IFS=, read -r operation_id image seed; do
    operation="projects/veo-testing/locations/us-central1/publishers/google/models/veo-001-preview-0815/operations/$operation_id"
    result=$(curl -s -X POST -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        https://us-central1-aiplatform.googleapis.com/v1beta1/projects/veo-testing/locations/us-central1/publishers/google/models/veo-001-preview-0815:fetchPredictOperation \
        -d '{operationName: "'$operation'"}')

    echo $result

    # 获取done状态
    done_status=$(echo $result | jq -r .done)

    if [ "$done_status" = "true" ]; then
        if echo "$result" | jq -e '.response.generatedSamples[0].video.uri' > /dev/null; then
            http_link=$(echo "$result" | jq -r '.response.generatedSamples[0].video.uri' | sed 's|gs://|https://storage.googleapis.com/|')
            echo "$operation_id,$http_link" >> data/batch_operation_result.csv
        fi
    fi
done  < data/batch_operation.csv

