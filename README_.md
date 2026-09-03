# DevOps Assignment – AWS Infrastructure, CI/CD, Monitoring & Logging

## 1. Project Overview

This project implements a production-oriented DevOps workflow for deploying a Node.js REST API on AWS.

The solution covers:

- Infrastructure provisioning using Terraform
- AWS VPC networking with public and private subnets
- EC2-based application hosting
- PostgreSQL database using Amazon RDS
- Application Load Balancer (ALB)
- Docker containerization
- Amazon ECR image storage
- GitHub Actions CI/CD
- Automated unit testing
- Trivy container vulnerability scanning
- GitHub Actions → AWS authentication using OIDC
- AWS Systems Manager (SSM) based deployment
- AWS Secrets Manager for database credentials
- Manual production approval
- CloudWatch monitoring and centralized logging
- Cost-conscious AWS architecture

---

## 2. Architecture

### High-Level Flow

```text
                         Internet
                            |
                            v
                 +----------------------+
                 | Application Load     |
                 | Balancer (ALB)       |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 | EC2 Application      |
                 | Docker Container     |
                 | Node.js :8080        |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 | Amazon RDS           |
                 | PostgreSQL :5432     |
                 | Private DB Subnets   |
                 +----------------------+

GitHub
   |
   v
GitHub Actions
   |
   +--> Unit Tests
   |
   +--> Docker Build
   |
   +--> Trivy Security Scan
   |
   +--> Push Image to ECR
   |
   +--> Deploy to Staging using SSM
   |
   +--> Manual Production Approval
   |
   +--> Deploy Approved Image to Production

AWS Secrets Manager
   |
   v
EC2 / Application
   |
   v
RDS PostgreSQL

EC2 / ALB / RDS
   |
   v
CloudWatch Metrics & Logs
```

### Network Design

The Terraform configuration creates:

- VPC: `10.0.0.0/16`
- Two public subnets
- Two private application subnets
- Two private database subnets
- Internet Gateway for public connectivity
- Separate route tables
- Security groups for ALB, application and RDS

The application EC2 instance is placed in a public subnet for this cost-conscious assignment architecture, while RDS remains private.

A NAT Gateway was intentionally not used to avoid unnecessary recurring AWS costs.

---

## 3. AWS Infrastructure

Infrastructure is managed using Terraform.

### Main Resources

- Amazon VPC
- Internet Gateway
- Public and private subnets
- Route tables and associations
- Application Load Balancer
- ALB target group and listener
- EC2 instance
- IAM role for EC2
- Amazon ECR repository
- Amazon RDS PostgreSQL
- RDS subnet group
- Security groups
- CloudWatch resources

### Infrastructure Configuration

Terraform variables are used for configurable values such as:

- AWS region
- CIDR blocks
- Instance configuration
- Database password

Sensitive Terraform state files and variable files are excluded using `.gitignore`.

---

## 4. Application

The application is a Node.js REST API using Express and Sequelize.

### API Endpoints

Health/root endpoint:

```text
GET /
```

Tutorial API:

```text
POST   /api/tutorials
GET    /api/tutorials
GET    /api/tutorials/:id
PUT    /api/tutorials/:id
DELETE /api/tutorials/:id
DELETE /api/tutorials
GET    /api/tutorials/published
```

The application listens on port `8080`.

---

## 5. Docker

The application is containerized using Docker.

The Docker image:

- Uses Node.js Alpine as the base image
- Installs application dependencies
- Copies application source
- Exposes port `8080`
- Starts the Node.js server

Example local build:

```bash
cd app
docker build -t devops-app .
```

Run locally:

```bash
docker run -p 8080:8080 devops-app
```

Database environment variables are supplied at runtime rather than hard-coded into the image.

---

## 6. Amazon ECR

Docker images are stored in Amazon Elastic Container Registry (ECR).

The CI/CD pipeline creates an immutable deployment reference using the Git commit SHA:

```text
devops-app:<github-sha>
```

This provides traceability between:

```text
Git commit -> Docker image -> ECR -> deployment
```

ECR image scanning is enabled, and Trivy performs an additional vulnerability scan in GitHub Actions.

---

## 7. CI/CD Pipeline

GitHub Actions is used for continuous integration and deployment.

### Pull Request CI

For pull requests targeting `main`:

```text
Pull Request
     |
     v
Checkout
     |
     v
Setup Node.js
     |
     v
npm ci
     |
     v
npm test
```

The test workflow prevents code from being merged without successful automated tests.

### Main Branch Deployment

After changes reach `main`:

```text
Push to main
     |
     v
Build Docker Image
     |
     v
Trivy Vulnerability Scan
     |
     v
Push Image to ECR
     |
     v
Deploy to Staging
     |
     v
Manual Production Approval
     |
     v
Deploy to Production
```

---

## 8. AWS Authentication from GitHub Actions

GitHub Actions uses AWS IAM OIDC instead of storing long-lived AWS access keys in the repository.

The workflow requests a temporary AWS role session using:

```text
github-actions-devops-role
```

The IAM trust policy restricts access to the project's GitHub repository and `main` branch.

This reduces the risk associated with long-lived AWS credentials.

---

## 9. Secret Management

Database credentials are stored in AWS Secrets Manager.

Secret:

```text
devops/rds
```

The application does not store the database password in the Docker image or Git repository.

The EC2 IAM role is granted permission to retrieve the required secret.

The deployment process obtains the secret at deployment time and supplies database configuration to the container through environment variables.

> Never commit database passwords, AWS access keys, secret values, `.env` files, or `terraform.tfvars` to Git.

---

## 10. Deployment

AWS Systems Manager (SSM) is used to execute deployment commands on EC2.

This avoids requiring SSH access for normal deployments.

Deployment steps:

1. GitHub Actions authenticates to AWS using OIDC.
2. Docker image is pulled from ECR.
3. SSM sends deployment commands to EC2.
4. The previous container is stopped and removed.
5. Database credentials are retrieved from Secrets Manager.
6. The new image is started.
7. Deployment status is checked.
8. The application is validated through the ALB.

---

## 11. Production Approval

Production deployment is protected using a GitHub Environment named:

```text
production
```

The environment has required reviewers enabled.

Therefore the pipeline cannot automatically complete the production deployment until an authorized reviewer approves it.

This provides the required manual production deployment gate.

---

## 12. Monitoring

AWS CloudWatch is used for infrastructure and application observability.

### Infrastructure Metrics

Monitoring includes:

- EC2 CPU utilization
- EC2 memory utilization
- EC2 disk utilization
- ALB request count
- ALB HTTP errors
- ALB target latency
- RDS CPU utilization
- RDS database connections
- RDS free storage

### Dashboards

Two CloudWatch dashboards are used:

**Infrastructure Dashboard**

- EC2 CPU
- EC2 memory
- EC2 disk
- ALB requests
- ALB errors

**Application & Database Dashboard**

- ALB latency
- ALB 4xx/5xx
- RDS CPU
- RDS connections
- RDS free storage

---

## 13. Centralized Logging

CloudWatch Logs is used to centralize application and system logs.

The monitoring setup provides visibility into:

- Application logs
- EC2/system logs
- Deployment-related logs
- Access/request information where configured

Centralized logging makes troubleshooting easier without requiring engineers to manually inspect individual server files.

---

## 14. Security Best Practices

Implemented security practices include:

- RDS is not publicly accessible.
- RDS is deployed in private database subnets.
- RDS accepts PostgreSQL traffic only from the application security group.
- Application traffic is restricted to the ALB security group.
- ALB accepts HTTP/HTTPS traffic.
- AWS authentication from GitHub uses OIDC.
- Database credentials are stored in Secrets Manager.
- SSM is used instead of normal SSH for deployments.
- Docker images are scanned with Trivy.
- Sensitive Terraform files are excluded from Git.
- ECR image scanning is enabled.

---

## 15. Cost Optimization

The architecture was designed with AWS cost awareness.

### Decisions

- NAT Gateway was not used because it creates additional recurring charges.
- RDS uses a small instance class suitable for the assignment.
- RDS is configured as single-AZ for the assignment rather than Multi-AZ.
- A small EC2 instance is used.
- CloudWatch is used instead of adding a separate monitoring stack requiring additional infrastructure.
- The same EC2 infrastructure is used for staging and production as a cost-saving assignment decision.

### Production Consideration

For a real production system, staging and production should normally use separate infrastructure/accounts or isolated environments.

The current design prioritizes demonstrating the required DevOps workflow while controlling AWS costs.

---

## 16. Testing

Unit testing is implemented using Jest and Supertest.

Example:

```bash
cd app
NODE_ENV=test npm test
```

The test verifies the application root endpoint:

```text
GET /
```

Expected response:

```json
{
  "message": "Welcome to bezkoder application."
}
```

---

## 17. Deployment Validation

After deployment, the application can be tested through the Application Load Balancer.

Example:

```bash
curl http://<ALB-DNS-NAME>/
```

Expected response:

```json
{
  "message": "Welcome to bezkoder application."
}
```

Tutorial API:

```bash
curl http://<ALB-DNS-NAME>/api/tutorials
```

---

## 18. Repository Structure

```text
devops-assignment/
├── app/
│   ├── app/
│   ├── tests/
│   ├── Dockerfile
│   ├── package.json
│   ├── package-lock.json
│   └── server.js
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── ...
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
│
├── docs/
│   ├── architecture.md
│   ├── security.md
│   ├── cost-optimization.md
│   └── challenges.md
│
├── README.md
└── .gitignore
```

---

## 19. How to Deploy

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Validate

```bash
terraform validate
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Get Outputs

```bash
terraform output
```

After infrastructure is available, push application changes to GitHub.

The GitHub Actions workflow handles:

```text
Test -> Build -> Scan -> ECR -> Staging -> Production Approval -> Production
```

---

## 20. Challenges and Resolutions

See:

```text
docs/challenges.md
```

for the detailed list of implementation challenges and resolutions.

---

## 21. Conclusion

This project demonstrates an end-to-end AWS DevOps implementation covering infrastructure as code, containerization, CI/CD, security, secret management, deployment automation, monitoring, centralized logging and production approval.

The architecture balances the assignment requirements with AWS cost considerations while following practical DevOps and cloud security practices.
