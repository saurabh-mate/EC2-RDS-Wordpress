# EC2-RDS-Wordpress# EC2-RDS-WordPress Deployment

## Overview
This project automates the deployment of a WordPress site on an AWS EC2 instance with an RDS MySQL database. The deployment uses Terraform for infrastructure provisioning, Ansible for server configuration, and Bash scripting for automation.

## Features
- **Automated AWS EC2 Instance Creation**
- **AWS RDS MySQL Setup**
- **Security Group Configuration**
- **Cloudflare DNS Setup for Custom Domain**
- **Automated WordPress Installation using Docker**
- **WP-CLI for WordPress Management**

## Prerequisites
- AWS Account with IAM access
- Terraform installed
- Ansible installed
- Cloudflare account with API token
- SSH key for EC2 access

## Deployment Steps

### 1. Clone the Repository
```bash
git clone https://github.com/your-repo/EC2-RDS-Wordpress.git
cd EC2-RDS-Wordpress
```

### 2. Configure Variables
Update `variables.tf` with your Cloudflare credentials:
```hcl
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}
```

### 3. Initialize and Apply Terraform
```bash
terraform init
terraform apply -auto-approve
```

### 4. Run Deployment Script
```bash
chmod +x deploy.sh
./deploy.sh
```
This script:
- Retrieves instance and database details
- Creates a `.env` file with database credentials
- Copies `.env` to the instance
- Runs the Ansible playbook
- Deploys WordPress with Docker

### 5. Access WordPress
- Website: [http://wordpress.purvesh.cloud](http://wordpress.purvesh.cloud)
- Admin Panel: [http://wordpress.purvesh.cloud/wp-admin](http://wordpress.purvesh.cloud/wp-admin)
- Admin Credentials:
  - Username: `admin`
  - Password: `Admin@123`


## Cleanup
To delete all resources:
```bash
terraform destroy -auto-approve
```

## Contributors
- **Saurabh Mate** - [GitHub](https://github.com/saurabh-mate)

