#!/bin/bash

# --- Existing Functions ---

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl command not found." >&2
        echo "Please install kubectl and ensure it's in your PATH and configured." >&2
        exit 1
    fi
}

get_namespace_option() {
    read -p "Enter Namespace (leave empty for default): " namespace
    if [[ -n "$namespace" ]]; then
        echo "-n $namespace"
    else
        echo ""
    fi
}

list_resources() {
    read -p "Enter resource type to list (e.g., pods, deployments, services, ns): " resource_type
    if [[ -z "$resource_type" ]]; then
        echo "Error: Resource type cannot be empty."
        return
    fi

    read -p "Enter Namespace (leave empty for all namespaces): " namespace

    namespace_option=""
    if [[ -n "$namespace" ]]; then
        namespace_option="-n $namespace"
    else
        if [[ "$resource_type" != "ns" ]]; then
            namespace_option="--all-namespaces"
        fi
    fi

    echo "Listing $resource_type $namespace_option..."
    kubectl get "$resource_type" $namespace_option
    if [ $? -ne 0 ]; then
        echo "kubectl command failed. Check resource type or Namespace."
    fi
}

get_logs() {
    read -p "Enter Pod name: " pod_name
    if [[ -z "$pod_name" ]]; then
        echo "Error: Pod name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    echo "Fetching logs for pod $pod_name $namespace_option..."
    kubectl logs "$pod_name" $namespace_option
    if [ $? -ne 0 ]; then
        echo "kubectl command failed. Check Pod name or Namespace."
    fi
}

describe_resource() {
    read -p "Enter resource type to describe (e.g., pod, deployment, svc): " resource_type
    if [[ -z "$resource_type" ]]; then
        echo "Error: Resource type cannot be empty."
        return
    fi
    read -p "Enter resource name: " resource_name
    if [[ -z "$resource_name" ]]; then
        echo "Error: Resource name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    echo "Describing $resource_type/$resource_name $namespace_option..."
    kubectl describe "$resource_type" "$resource_name" $namespace_option
    if [ $? -ne 0 ]; then
        echo "kubectl command failed. Check resource type, name, or Namespace."
    fi
}

exec_in_pod() {
    read -p "Enter Pod name: " pod_name
    if [[ -z "$pod_name" ]]; then
        echo "Error: Pod name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    read -p "Enter command to execute inside the pod (e.g., /bin/bash, ls /): " command_to_exec
    if [[ -z "$command_to_exec" ]]; then
        echo "Error: Command cannot be empty."
        return
    fi

    echo "Executing '$command_to_exec' in pod $pod_name $namespace_option..."
    kubectl exec "$pod_name" $namespace_option -- $command_to_exec
    if [ $? -ne 0 ]; then
        echo "kubectl command failed. Check Pod name, Namespace, or command."
    fi
}

delete_resource() {
    read -p "Enter resource type to delete (e.g., pod, deployment, svc): " resource_type
    if [[ -z "$resource_type" ]]; then
        echo "Error: Resource type cannot be empty."
        return
    fi
    read -p "Enter resource name: " resource_name
    if [[ -z "$resource_name" ]]; then
        echo "Error: Resource name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    read -p "Are you sure you want to delete $resource_type/$resource_name $namespace_option? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        echo "Deleting $resource_type/$resource_name $namespace_option..."
        kubectl delete "$resource_type" "$resource_name" $namespace_option
        if [ $? -eq 0 ]; then
            echo "Resource deleted successfully."
        else
            echo "kubectl command failed. Check resource type, name, or Namespace."
        fi
    else
        echo "Deletion cancelled."
    fi
}

apply_yaml() {
    read -p "Enter path to the YAML configuration file: " yaml_file
    if [[ -z "$yaml_file" ]]; then
        echo "Error: File path cannot be empty."
        return
    fi
    if [[ ! -f "$yaml_file" ]]; then
        echo "Error: File '$yaml_file' not found."
        return
    fi

    namespace_option=$(get_namespace_option)

    echo "Applying configuration from '$yaml_file' $namespace_option..."
    kubectl apply -f "$yaml_file" $namespace_option
    if [ $? -eq 0 ]; then
        echo "Configuration applied successfully."
    else
        echo "kubectl apply command failed."
    fi
}

edit_resource() {
    read -p "Enter resource type to edit (e.g., pod, deployment, svc): " resource_type
    if [[ -z "$resource_type" ]]; then
        echo "Error: Resource type cannot be empty."
        return
    fi
    read -p "Enter resource name: " resource_name
    if [[ -z "$resource_name" ]]; then
        echo "Error: Resource name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    echo "Editing $resource_type/$resource_name $namespace_option..."
    kubectl edit "$resource_type" "$resource_name" $namespace_option
    if [ $? -eq 0 ]; then
        echo "Resource edited successfully."
    else
        echo "kubectl edit command failed."
    fi
}

# --- New Functions ---

restart_pod() {
    read -p "Enter Pod name to restart: " pod_name
    if [[ -z "$pod_name" ]]; then
        echo "Error: Pod name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    echo "Restarting Pod $pod_name $namespace_option by deleting it..."
    kubectl delete pod "$pod_name" $namespace_option
}

port_forward() {
    read -p "Enter Pod/Service name: " pod_or_service
    if [[ -z "$pod_or_service" ]]; then
        echo "Error: Name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    read -p "Enter local port: " local_port
    read -p "Enter target port: " target_port

    echo "Starting port-forward from localhost:$local_port to $pod_or_service:$target_port..."
    kubectl port-forward $namespace_option "$pod_or_service" "$local_port":"$target_port"
}

view_events() {
    namespace_option=$(get_namespace_option)

    echo "Fetching Kubernetes events $namespace_option..."
    kubectl get events $namespace_option --sort-by='.metadata.creationTimestamp'
}

switch_context() {
    echo "Available contexts:"
    kubectl config get-contexts
    read -p "Enter context name to switch to: " context
    kubectl config use-context "$context"
}

scale_deployment() {
    read -p "Enter deployment name to scale: " deployment_name
    if [[ -z "$deployment_name" ]]; then
        echo "Error: Deployment name cannot be empty."
        return
    fi
    namespace_option=$(get_namespace_option)

    read -p "Enter number of replicas: " replicas

    echo "Scaling deployment $deployment_name to $replicas replicas..."
    kubectl scale deployment "$deployment_name" $namespace_option --replicas="$replicas"
}

check_nodes_status() {
    echo "Checking nodes status..."
    kubectl top nodes
}

check_resource_usage() {
    echo "Checking pods resource usage..."
    kubectl top pods --all-namespaces
}

# --- Menu ---

show_menu() {
    echo "-----------------------------------------------------"
    echo "  Kubernetes Management Script  "
    echo "-----------------------------------------------------"
    echo " 1) List resources (Pods, Deployments, etc.)"
    echo " 2) Get Pod logs"
    echo " 3) Describe a resource"
    echo " 4) Execute command in a Pod"
    echo " 5) Delete a resource"
    echo " 6) Apply configuration from YAML file"
    echo " 7) Edit a resource"
    echo " 8) Restart a Pod"
    echo " 9) Port Forward to a Pod/Service"
    echo "10) View Cluster Events"
    echo "11) Switch Kubernetes Context"
    echo "12) Scale a Deployment"
    echo "13) Check Node Status"
    echo "14) Check Resource Usage"
    echo "15) Exit"
}

# --- Main loop ---

check_kubectl

while true; do
    show_menu
    read -p "Choose an option: " choice

    case $choice in
        1) list_resources ;;
        2) get_logs ;;
        3) describe_resource ;;
        4) exec_in_pod ;;
        5) delete_resource ;;
        6) apply_yaml ;;
        7) edit_resource ;;
        8) restart_pod ;;
        9) port_forward ;;
       10) view_events ;;
       11) switch_context ;;
       12) scale_deployment ;;
       13) check_nodes_status ;;
       14) check_resource_usage ;;
       15) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please select a valid choice." ;;
    esac
    echo
done
