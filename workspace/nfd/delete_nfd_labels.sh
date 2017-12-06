#!/bin/bash

labels=($(sudo kubectl get nodes -o json | jq .items[].metadata.labels | grep node.alpha | awk -F '"' '{print $2}'))

unique_labels=($(echo "${labels[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

for i in "${unique_labels[@]}"
do
        echo $i
        sudo kubectl label nodes --all $i-
done
