#!/usr/bin/env bash

# Global variable to store pods list
PODS=""
PODS_ARRAY=()
INIT_CONTAINERS_ARRAY=()
MAIN_CONTAINERS_ARRAY=()
CONTAINERS_ARRAY=()

# Function to list all pods with numeric identifiers and additional info
list_pods() {
    echo "Listing all pods in current namespace..."
    printf "%-4s %-40s %-16s %-30s %-12s\n" "ID" "POD NAME" "POD IP" "NODE NAME" "STATUS"

    # Get all pod information in a single kubectl command
    pods_json=$(kubectl get pods -o json)

    # Store the pod names in PODS global variable
    PODS=$(echo "$pods_json" | jq -r '.items[].metadata.name')

    # Convert newline-separated list to array
    mapfile -t PODS_ARRAY <<< "$PODS"

    # Loop through pods and display info with numeric identifiers
    counter=0
    for pod in "${PODS_ARRAY[@]}"; do
        # Extract pod information from the JSON using jq
        pod_info=$(echo "$pods_json" | jq -r ".items[] | select(.metadata.name == \"$pod\")")
        pod_ip=$(echo "$pod_info" | jq -r '.status.podIP // "N/A"')
        node_name=$(echo "$pod_info" | jq -r '.spec.nodeName // "N/A"')
        status=$(echo "$pod_info" | jq -r '.status.phase // "Unknown"')

        printf "%-4s %-40s %-16s %-30s %-12s\n" "$counter)" "$pod" "$pod_ip" "$node_name" "$status"
        ((counter++))
    done
}

# Function to list all containers in a specific pod
list_containers() {
    pod_index=$1
    with_init_containers=${2:-false}

    # Check if the index is valid
    if [[ $pod_index -lt 0 || $pod_index -ge ${#PODS_ARRAY[@]} ]]; then
        echo "Invalid pod index!"
        return 1
    fi

    selected_pod=${PODS_ARRAY[$pod_index]}
    echo "Listing containers for pod: $selected_pod"
    printf "%-4s %-25s %-80s %-10s %-10s %-10s\n" "ID" "CONTAINER NAME" "IMAGE" "STATE" "READY" "RESTARTS"

    # Get all pod information in a single kubectl command
    pod_json=$(kubectl get pod "$selected_pod" -o json)

    # Check for init containers
    counter=0
    if [[ "x$with_init_containers" == "xtrue" ]]; then
        init_containers=$(echo "$pod_json" | jq -r '.spec.initContainers[]?.name' 2>/dev/null)
        if [ ! -z "$init_containers" ]; then
            echo "Init Containers:"
            mapfile -t INIT_CONTAINERS_ARRAY <<< $init_containers 
            for container in ${INIT_CONTAINERS_ARRAY[@]}; do
                # Get container information
                image=$(echo "$pod_json" | jq -r ".spec.initContainers[] | select(.name == \"$container\") | .image")

                # Get container status (if available)
                container_status=$(echo "$pod_json" | jq -r ".status.initContainerStatuses[] | select(.name == \"$container\")")
                container_ready=$(echo "$container_status" | jq -r '.ready // "false"')
                container_restarts=$(echo "$container_status" | jq -r '.restartCount // "0"')

                # Determine container state
                container_state="Unknown"
                if echo "$container_status" | jq -e '.state.running' > /dev/null 2>&1; then
                    container_state="Running"
                elif echo "$container_status" | jq -e '.state.terminated' > /dev/null 2>&1; then
                    container_state="Terminated"
                elif echo "$container_status" | jq -e '.state.waiting' > /dev/null 2>&1; then
                    container_state="Waiting"
                fi

                printf "%-4s %-25s %-80s %-10s %-10s %-10s\n" "$counter)" "$container" "$image" "$container_state" "$container_ready" "$container_restarts"
                ((counter++))
        done
        fi
    fi

    # List regular containers
    echo "Containers:"
    containers=$(echo "$pod_json" | jq -r '.spec.containers[]?.name')
    mapfile -t MAIN_CONTAINERS_ARRAY <<< $containers 
    for container in ${MAIN_CONTAINERS_ARRAY[@]}; do
        # Get container information
        image=$(echo "$pod_json" | jq -r ".spec.containers[] | select(.name == \"$container\") | .image")

        # Get container status (if available)
        container_status=$(echo "$pod_json" | jq -r ".status.containerStatuses[] | select(.name == \"$container\")")
        container_ready=$(echo "$container_status" | jq -r '.ready // "false"')
        container_restarts=$(echo "$container_status" | jq -r '.restartCount // "0"')

        # Determine container state
        container_state="Unknown"
        if echo "$container_status" | jq -e '.state.running' > /dev/null 2>&1; then
            container_state="Running"
        elif echo "$container_status" | jq -e '.state.terminated' > /dev/null 2>&1; then
            container_state="Terminated"
        elif echo "$container_status" | jq -e '.state.waiting' > /dev/null 2>&1; then
            container_state="Waiting"
        fi

        printf "%-4s %-25s %-80s %-10s %-10s %-10s\n" "$counter)" "$container" "$image" "$container_state" "$container_ready" "$container_restarts"
        ((counter++))
    done

    CONTAINERS_ARRAY=("${INIT_CONTAINERS_ARRAY[@]}" "${MAIN_CONTAINERS_ARRAY[@]}")
}
