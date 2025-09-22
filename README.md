# eksctl_terraform

Provision an **EKS Cluster** using Terraform with S3 remote backend.

---

## 🚀 Steps to Run

1. **Update your details**  
   - Add your **Key Pair Name** in `dev.tfvars`.  
   - Update your **Private Key Path** (used for provisioning).  
   - Configure AWS CLI with your `Access Key` and `Secret Key`.  

2. **Create S3 bucket for Terraform state**
   - First, comment out the backend block in `main.tf`.  
   - Run:
     ```sh
     terraform init
     terraform apply
     ```
   - This creates the S3 bucket.

3. **Enable S3 backend**
   - Uncomment the backend block in `main.tf`.  
   - Re-initialize Terraform:
     ```sh
     terraform init -reconfigure
     ```

4. **Deploy EKS Cluster**
   ```sh
   terraform plan -var-file="dev.tfvars"
   terraform apply -var-file="dev.tfvars" -auto-approve
5. **Destroy If you need**
   ```sh
   terraform estroy -var-file="dev.tfvars" -auto-approve
