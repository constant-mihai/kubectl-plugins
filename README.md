# kubectl plugins

Various productivity plugins for kubectl.

## kubectl kubeconfig

**kubectl kubeconfig** manages kube config files. When creating a new configuration file it will store it under the following path:
```
/home/user/.kube/config.d/aws-profile.region.cluster-name/namespace.yaml
```
It will **not** append multiple contexts under a single file. Storing one context per file allows the user to isolate kubernetes contexts to terminal windows.
If you prefer using a single kube config file or to manage these files on your own, then don't use **kubectl kubeconfig**.

## kubectl pod-ops

**kubectl pod-ops** is a short hand for various pod operations like listing, exec or copy.

## Example usage
```
# kubectl kubeconfig create --profile aws-profile --region region --name cluster-name --namespace namespace
# kubectl kubeconfig list aws-profile region namespace
export KUBECONFIG=/home/user/.kube/config.d/aws-profile.region.cluster-name/namespace.yaml
```

This lists both namespaces in the kubernetes cluster and namespaces which have their own kubeconfig file. The search_string will try to be matched.
```
# kubectl kubeconfig list-namespaces search_string
```
