# kubectl plugins

## Example usage
```
# kubectl kubeconfig create --profile dev --region us-west-1 --name cluster-name --namespace namespace
# kubectl kubeconfig list dev us-west-1 namespace
export KUBECONFIG=/home/user/.kube/config.d/dev.us-west-1.cluster-name/namespace.yaml
```

To switch a context, if the namespace is not provided, it will switch you to a default context which doesn't have a namespace:
```
# kubectl kubeconfig switch-context profile region cluster-name [namespace]
```

This lists both namespaces in the kubernetes cluster and namespaces which have their own kubeconfig file. The search_string will try to be matched.
```
# kubectl kubeconfig list-namespaces search_string
```

To switch to a different namespace in the same context:
```
# kubectl kubeconfig switch-namespace namespace
```
