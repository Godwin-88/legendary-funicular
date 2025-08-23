# Work in Progress

## Step 1: Dockerfile

Created a multi-stage `Dockerfile` to build container images for the project's services. This approach optimizes image size and build times.

**Key Features:**
- **Common Base Image:** A `base` stage installs Python and all dependencies from `requirements.txt`.
- **Service-Specific Images:** Separate final stages for the `api` and `executor` services ensure the images are lightweight and secure.
- **Non-Root User:** A non-root user (`app`) is created and used for security best practices.

**Build Commands:**
- **API Service:** `docker build --target api -t drl-api:latest .`
- **Executor Service:** `docker build --target executor -t drl-executor:latest .`

## Step 2: Dependencies

Populated the `requirements.txt` file with a comprehensive list of Python libraries required for the project, based on the architecture described in `context.md`. The dependencies are grouped into the following categories:

- MLOps & Orchestration
- ML & Deep Reinforcement Learning
- API & Services
- Graph Database (Neo4j)
- Blockchain (Ethereum)
- Tooling & Code Quality
- Utilities

## Step 3: Terraform Baseline

Established a modular Terraform configuration in the `deployment/terraform` directory to manage infrastructure as code.

**Key Features:**
- **Environment-based Structure:** Code is organized into environments (e.g., `staging`) to manage different deployment targets.
- **Remote State Backend:** Configured to use an S3 backend for secure and collaborative state management.
- **Baseline Resources:** Includes a sample resource for an MLflow S3 artifacts bucket and placeholders for key components like VPC, EKS, and Neo4j.

### How the Terraform Baseline Works

The fundamental idea is **Infrastructure as Code (IaC)**. Instead of manually configuring cloud resources, we define them in code for automation, consistency, and version control.

**1. Directory Structure:**
- `deployment/terraform/`: The root for all infrastructure code.
- `main.tf` (root): Declares the cloud provider (AWS) and configures the S3 remote backend for shared state management.
- `variables.tf` (root): Defines global variables like project name and region for consistency.
- `environments/staging/`: A workspace for a specific deployment environment. This isolates staging resources from production.
- `environments/staging/main.tf`: Defines the actual AWS resources (like S3 buckets, Kubernetes clusters, etc.) for the staging environment.
- `environments/staging/outputs.tf`: Declares outputs from the infrastructure, like the auto-generated name of an S3 bucket.

**2. The Workflow:**
1.  **Initialization:** Navigate to an environment's directory (`environments/staging/`) and run `terraform init`. This downloads necessary plugins and connects to the remote S3 backend.
2.  **Planning:** Run `terraform plan`. Terraform generates a detailed report of what it will create, change, or delete, allowing for a safe review before making any changes.
3.  **Applying:** Run `terraform apply`. Terraform executes the plan and builds the infrastructure in your AWS account.

This structured approach ensures your infrastructure is managed in a safe, repeatable, and collaborative way.

### Cloud Provider Free Tier Analysis

#### AWS (Amazon Web Services)

The AWS Free Tier is excellent for **starting** this project, but it is **not sufficient** for the full, end-to-end system, especially the compute-intensive parts.

- **What Works:** Core MLOps scaffolding (MLflow, Airflow, etc.) on `t2.micro` EC2 instances; initial storage/database needs via S3, RDS, and Neo4j Aura's own free tier.
- **What Exceeds:** The primary cost is **Model Training**, which requires powerful CPU/GPU instances not in the free tier. The **EKS Control Plane** also has an hourly cost (~$72/month). Large data volumes and running multiple services 24/7 will also incur costs.
- **Recommendation:** Use the free tier to build the project's skeleton, but budget for paid compute resources (especially for model training) and use cost monitoring tools.

#### Microsoft Azure

Azure's free offering is a strong contender, with one significant advantage for this project's architecture.

- **The Big Advantage: Kubernetes (AKS):** The **AKS cluster management is completely free**. You only pay for the worker node VMs, for which you can use free-tier eligible `B1S` VMs during development. This can make the core orchestration layer significantly cheaper than on AWS.
- **What Works:** Similar to AWS, the free tier provides a `B1S` VM (750 hours), 5 GB of Blob Storage, and a small managed database suitable for the MLOps scaffolding.
- **What Exceeds:** As with AWS, **Model Training** is the main cost and requires powerful, paid VMs. The 5 GB storage limit and 750-hour VM limit present the same constraints.
- **Recommendation:** Azure is likely more cost-effective for the **infrastructure and orchestration** part of this project due to the free AKS management. The most significant cost, model training, will be a paid service on both platforms.