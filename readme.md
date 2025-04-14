# **Automated AWS Infrastructure and CI/CD Pipeline**

## **Introduction**

This project automates the provisioning and management of AWS infrastructure using **Terraform**, along with **Docker** deployment on EC2 instances, and integrates these operations into a **CI/CD pipeline** using **Jenkins**. The project aims to streamline the process of creating and managing AWS resources, deploying applications, and automating the entire workflow.

Key components of the infrastructure include:
- **Virtual Private Cloud (VPC)** with subnets, security groups, and EC2 instances.
- **Docker containers** deployed on EC2 instances.
- **Kubernetes Cluster (EKS)** provisioned on AWS for container orchestration.
- **S3 Backend for Terraform State Management** for remote storage and versioning of Terraform state files.
- **State Locking** with **DynamoDB** to avoid race conditions during deployments.
- **CI/CD pipeline** integration using Jenkins to automate infrastructure provisioning.

---

## **Key Features**

- **Reusable Terraform Modules**: Modular architecture to simplify the management of AWS resources such as VPCs, EC2 instances, and Security Groups.
  
- **Docker Container Deployment**: Automated deployment of Docker containers on EC2 instances after provisioning, ensuring consistency across environments.

- **Kubernetes on AWS (EKS)**: Full setup of a Kubernetes cluster on AWS, enabling container orchestration with integrated worker nodes and IAM roles.

- **S3 Backend for Remote State Storage**: Terraform state is stored in an **AWS S3 bucket**, enabling shared access to the state files across different team members and automated workflows. This ensures that the infrastructure is consistently managed and avoids conflicts during deployments.

- **State Locking with DynamoDB**: **DynamoDB** is used for **state locking** to prevent simultaneous modifications to the Terraform state, ensuring safe and coordinated deployments, especially in team environments.

- **CI/CD Pipeline Integration**: A **Jenkins pipeline** is already set up in the repository, automating Terraform operations, including provisioning AWS resources and deploying applications. This ensures that infrastructure changes are part of the same pipeline that handles application code changes.

---

## **Prerequisites**

Before you begin, ensure that you have the following:

1. **AWS Account** with appropriate permissions to manage resources like EC2, VPC, S3, EKS, IAM roles, etc.  
   - [Create an AWS Account](https://aws.amazon.com/free/)
   - [AWS IAM Permissions Overview](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_permissions.html)
   
2. **Terraform** installed (version 1.0 or higher).  
   - [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

3. **AWS CLI** configured with your credentials.  
   - [Install and Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

4. **Jenkins** setup to run Terraform commands (optional for CI/CD integration).  
   - [Install Jenkins](https://www.jenkins.io/doc/book/installing/linux/)
   - [Jenkins Setup and Configuration](https://www.jenkins.io/doc/book/)

5. **Git** to clone the repository.  
   - [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

---

## **Setup Instructions**

Follow these steps to set up and run the project:

### 1. **Clone the GitHub Repository**

Clone this repository to your local machine:

```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
```

### 2. **Configure AWS Credentials**

Ensure your AWS credentials are configured on your local machine or in the CI/CD environment:

- Using the AWS CLI:
  ```bash
  aws configure
  ```
  then follow the prompts to enter your access key and secret access key.

Alternatively, you can set environment variables for AWS access keys:
```bash
export AWS_ACCESS_KEY_ID=your-access-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-access-key
```

### 3. **Initialize Terraform**

Navigate to the project directory and initialize Terraform:

```bash
terraform init
```

This command initializes Terraform, downloads the necessary providers, and sets up the backend for storing state files remotely in **S3**.

### 4. **Set Up the Remote Backend (S3 + DynamoDB)**

Terraform state files will be stored in an AWS S3 bucket. You need to configure the following in your **AWS account**:
- **S3 Bucket** for storing state files.
- **DynamoDB Table** for state locking.

Once you’ve configured these resources, make sure to update the `backend` configuration in the `main.tf` file if needed.

### 5. **Run Terraform Plan**

To verify the infrastructure changes that Terraform will apply, run:

```bash
terraform plan
```

This will show a summary of the resources that will be created, modified, or destroyed. Ensure the plan looks correct before proceeding.

### 6. **Apply the Terraform Configuration**

Once you're satisfied with the `terraform plan`, apply the configuration to provision the AWS resources:

```bash
terraform apply
```

Terraform will prompt you to confirm the changes. Type `yes` to proceed with the infrastructure provisioning.

### 7. **Verify Deployment**

After Terraform successfully applies the configuration, you can verify the deployment by checking the following AWS resources:
- **EC2 Instances**: Ensure that the EC2 instances are running as expected.
- **Docker Containers**: Check if the Docker containers are deployed and running on the EC2 instances.
- **EKS Cluster**: Ensure the Kubernetes cluster is up and running.

---

## **CI/CD Pipeline (Jenkins Integration)**

A **Jenkinsfile** is already provided in the repository for automating Terraform steps as part of the CI/CD pipeline. You can use this file to integrate infrastructure provisioning into your Jenkins setup.

### 1. **Set Up Jenkins**

Ensure that **Jenkins** is installed and running. If not, you can follow the installation instructions below:
- [Install Jenkins](https://www.jenkins.io/doc/book/installing/)

### 2. **Configure Jenkins Pipeline**

- Add this repository as a **Jenkins project** and link it to your version control system (GitHub, GitLab, etc.).
- The **Jenkinsfile** will automatically trigger the following pipeline steps:
  - **Terraform Init**
  - **Terraform Plan**
  - **Terraform Apply**
  - **Terraform Destroy**

Ensure Jenkins has access to your AWS credentials by either:
- Using **environment variables** or
- Configuring an **IAM role** for Jenkins to access AWS.

### 3. **Run Jenkins Pipeline**

Once the Jenkins job is configured, you can trigger the pipeline to automatically provision infrastructure and deploy Docker containers, ensuring that changes are applied in an automated and reliable manner.

---

## **Cleaning Up Resources**

To avoid incurring unnecessary AWS charges, you can safely destroy the provisioned infrastructure by setting the `DESTROY_INFRASTRUCTURE` parameter to `true` before triggering the Jenkins job. This will initiate the `terraform destroy` command as part of the pipeline.

During the process, Terraform will display a detailed plan of the resources scheduled for destruction and prompt for confirmation. Review the plan carefully to ensure only the intended resources are being removed as it will be done non-interactively.

---

## **Accessing and Managing the EKS Cluster**

Follow these steps to interact with the EKS cluster after it has been created:

### **1. Update kubeconfig for the Target EKS Cluster**

Run the following command to update your kubeconfig file with the target EKS cluster:

```bash
aws eks update-kubeconfig --name <cluster-name>
```

Replace `<cluster-name>` with the name of your EKS cluster.

---

### **2. Edit the `aws-auth` ConfigMap**

The `aws-auth` ConfigMap in the `kube-system` namespace is used to manage credentials for accessing the cluster.

#### Use `kubectl` to edit the ConfigMap:

```bash
kubectl edit -n kube-system configmap/aws-auth
```

This command opens the `aws-auth` ConfigMap in your default editor.

---

### **3. Add IAM Role or User to the ConfigMap**

#### **For IAM Roles:**

In the `aws-auth` ConfigMap, under the `mapRoles` section, add the IAM role ARN you want to grant access to. Map it to a Kubernetes role (e.g., `system:masters` for admin access):

```yaml
apiVersion: v1
data:
    mapRoles: |
        - rolearn: arn:aws:iam::<account-id>:role/MyEksNodeGroupRole
            username: my-eks-node-group
            groups:
                - system:masters
```

- **`rolearn`**: Replace with the actual ARN of the IAM role.
- **`username`**: Specify a Kubernetes username (can be any name).
- **`groups`**: Define the Kubernetes groups this role will belong to. For admin access, use `system:masters`.

---

#### **For IAM Users:**

To add a specific IAM user, use the `mapUsers` section:

```yaml
apiVersion: v1
data:
    mapUsers: |
        - userarn: arn:aws:iam::<account-id>:user/my-eks-user
            username: my-eks-user
            groups:
                - system:masters
```

- **`userarn`**: Replace with the actual ARN of the IAM user.
- **`username`**: Specify a Kubernetes username for the IAM user.
- **`groups`**: Define the Kubernetes groups this user will belong to (e.g., `system:masters` for admin access).

---

### **4. Save and Exit**

After making the necessary updates to the `aws-auth` ConfigMap, save the changes and exit the editor. The updates will take effect immediately.

## **Important Notes**

- **State Management**: Terraform’s state is stored remotely in an **S3 bucket**. The state file contains sensitive data (such as instance IDs, IP addresses, etc.), so ensure the S3 bucket has appropriate permissions and access control.
  
- **State Locking**: State locking is managed through **DynamoDB** to prevent multiple team members from applying conflicting changes to the infrastructure simultaneously.

- **Security**: Always ensure sensitive credentials are not hardcoded in Terraform files. Use environment variables or a secrets manager (e.g., AWS Secrets Manager, HashiCorp Vault) to handle sensitive data.

---

## **Resources**

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)

---

## **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---