# To access or interact with the cluster after creation, follow the steps below:

### 1. Update your kubeconfig with the target EKS cluster
Run the command:
```bash
aws eks update-kubeconfig --name <cluster-name>
```

### 2. Edit the `aws-auth` ConfigMap in the `kube-system` namespace
This is where credentials to access the cluster are stored.

#### Use `kubectl` to edit the `aws-auth` ConfigMap:
```bash
kubectl edit -n kube-system configmap/aws-auth
```
This will open the `aws-auth` ConfigMap in your default editor.

---

### 3. Add IAM Role or User to the ConfigMap

#### For IAM Roles:
In the `aws-auth` ConfigMap, under the `mapRoles` section, add your IAM role ARN to the `rolearn` field, and map it to a Kubernetes role (e.g., `system:masters` for admin access):

```yaml
apiVersion: v1
data:
    mapRoles: |
        - rolearn: arn:aws:iam::711387121692:role/MyEksNodeGroupRole
            username: my-eks-node-group
            groups:
                - system:masters
```

- **`rolearn`**: Your IAM role ARN (replace with the actual ARN of the role you want to allow).
- **`username`**: A Kubernetes username (you can use any name here).
- **`groups`**: The Kubernetes groups this role/user will belong to. For example, `system:masters` grants admin privileges.

---

#### For IAM Users:
If you want to add a specific IAM user, use the `mapUsers` section:

```yaml
apiVersion: v1
data:
    mapUsers: |
        - userarn: arn:aws:iam::711387121692:user/my-eks-user
            username: my-eks-user
            groups:
                - system:masters
```

- **`userarn`**: The IAM user's ARN.
- **`username`**: The username you want the IAM user to have in the Kubernetes cluster.
- **`groups`**: The Kubernetes groups this user will belong to (e.g., `system:masters` for admin access).

---

### 4. Save and exit
After updating the `aws-auth` ConfigMap with the correct IAM role or user, save the changes.
