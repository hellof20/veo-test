#!/bin/bash

prompts="$1"
seed="$2"
aspect_ratio="$3"
image="$4"
mimeType="$5"

output="gs://pwm-lowa/veo-outputs"
token=$(gcloud auth print-access-token)

echo $#

if [ $# -eq 5 ]; then
    data="{\"instances\": [{\"prompt\": \"$prompts\",\"image\": {\"gcsUri\": \"$image\", \"mimeType\": \"$mimeType\"}}],\"parameters\": {\"storageUri\": \"$output\",\"seed\": $seed,\"aspectRatio\": \"$aspect_ratio\"}}"
fi

if [ $# -eq 3 ]; then
    data="{\"instances\": [{\"prompt\": \"$prompts\"}],\"parameters\": {\"storageUri\": \"$output\",\"seed\": $seed,\"aspectRatio\": \"$aspect_ratio\"}}"
fi

result=$(curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" https://us-central1-aiplatform.googleapis.com/v1beta1/projects/veo-testing/locations/us-central1/publishers/google/models/veo-001-preview-0815:predictLongRunning -d "$data")

operation=$(echo $result|jq -r .name)


while true; do
    # 执行curl命令并存储结果
    result=$(curl -s -X POST -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        https://us-central1-aiplatform.googleapis.com/v1beta1/projects/veo-testing/locations/us-central1/publishers/google/models/veo-001-preview-0815:fetchPredictOperation \
        -d '{operationName: "'$operation'"}')

    # 获取done状态
    done_status=$(echo $result | jq -r .done)
    # echo "$(date '+%Y-%m-%d %H:%M:%S') - Processing..."

    if [ "$done_status" = "true" ]; then
        if echo "$result" | jq -e '.response.generatedSamples[0].video.uri' > /dev/null; then
            echo "$result" | jq -r '.response.generatedSamples[0].video.uri' | sed 's|gs://|https://storage.googleapis.com/|'
        else
            echo "$result"
        fi
        # uri=$(echo $result | jq -r '.response.generatedSamples[0].video.uri') # 提取uri值
        echo "$result,$image,$seed,$aspect_ratio,$prompts" >> result.csv
        break
    fi

    sleep 15
done