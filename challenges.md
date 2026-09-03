# Challenges and Resolutions

## 1. PostgreSQL RDS Connection and SSL

### Challenge

The Node.js application initially had difficulty connecting to the PostgreSQL RDS instance because the RDS PostgreSQL connection required SSL configuration.

### Resolution

The Sequelize PostgreSQL configuration was updated to pass the SSL options correctly through `dialectOptions`.

The configuration was also updated so that:

- RDS hostname is supplied through environment variables.
- Database credentials are not hard-coded.
- PostgreSQL uses SSL for the RDS connection.

### Result

The application successfully connected to the PostgreSQL RDS database.

---

## 2. Docker Container Deployment

### Challenge

The application worked locally, but the production-style deployment required the application to run consistently inside a Docker container.

There were also initial container/runtime issues involving ports and environment variables.

### Resolution

A Dockerfile was added using a Node.js Alpine base image.

The container:

- Installs dependencies
- Copies the application
- Exposes port `8080`
- Starts `server.js`

Database configuration is provided at runtime using environment variables.

### Result

The application runs successfully as a Docker container on EC2.

---

## 3. ECR Authentication and Image Push

### Challenge

The Docker image needed to be built by GitHub Actions and pushed securely to Amazon ECR.

Using long-lived AWS access keys in GitHub Actions would create unnecessary credential-management risk.

### Resolution

Amazon ECR was configured as the container registry and GitHub Actions was integrated with AWS using IAM OIDC.

The workflow:

1. Authenticates using OIDC.
2. Logs in to ECR.
3. Builds the Docker image.
4. Scans the image.
5. Pushes the image using the Git commit SHA as the tag.

### Result

GitHub Actions can securely push deployment images to ECR without storing long-lived AWS access keys in the repository.

---

## 4. GitHub Actions OIDC Configuration

### Challenge

GitHub Actions needed permission to access AWS resources without exposing permanent AWS credentials.

### Resolution

An AWS IAM OIDC provider was configured for:

```text
https://token.actions.githubusercontent.com
```

A dedicated IAM role was created for GitHub Actions.

The trust policy restricts the role to the intended repository and `main` branch.

### Result

The CI/CD pipeline can obtain temporary AWS credentials securely through OIDC.

---

## 5. Secure Database Credential Management

### Challenge

The application needs database credentials during deployment, but passwords should not be committed to GitHub or embedded in the Docker image.

### Resolution

AWS Secrets Manager was introduced.

The database secret stores the required connection information.

The EC2 IAM role receives only the required `secretsmanager:GetSecretValue` permission for the application secret.

During deployment, the secret is retrieved and supplied to the application container at runtime.

### Result

Database credentials are separated from application source code and Docker images.

---

## 6. EC2 Deployment Without Direct SSH

### Challenge

The application needed to be deployed automatically to EC2 from GitHub Actions.

Direct SSH would require maintaining SSH credentials and exposing port 22.

### Resolution

AWS Systems Manager Session Manager/Run Command was used.

GitHub Actions sends deployment commands through SSM to the EC2 instance.

The EC2 instance has an IAM role with the required SSM permissions.

### Result

Automated deployments work without requiring normal SSH access.

---

## 7. Temporary SSH Access During Troubleshooting

### Challenge

During initial infrastructure troubleshooting, temporary SSH access was required to inspect the EC2 server.

### Resolution

A temporary SSH security-group rule was added for the administrator's current public IP.

Once SSM-based administration was working, the SSH rule was intended to be removed.

### Lesson

SSH should not remain open unnecessarily. SSM is preferred for normal administration and deployment.

---

## 8. Git Repository Structure

### Challenge

The `app` directory initially contained its own Git repository. This caused the application to behave like a nested repository instead of normal project files inside the main repository.

### Resolution

The nested `.git` directory was removed from `app`, allowing the root repository to track the application normally.

### Result

The complete project is managed as one Git repository.

---

## 9. Package Lock File and CI Dependency Installation

### Challenge

GitHub Actions uses `npm ci`, which requires a valid `package-lock.json`.

The lock file was initially excluded by the repository ignore configuration.

### Resolution

The application lock file was explicitly added to the repository.

### Result

The CI workflow can run:

```bash
npm ci
npm test
```

reliably.

---

## 10. CI Test Setup

### Challenge

The application did not initially have an automated test suitable for the GitHub Actions pipeline.

### Resolution

Jest and Supertest were introduced.

A test was created for:

```text
GET /
```

The test validates the expected HTTP status and response body.

The application was also adjusted so that database synchronization is skipped when:

```text
NODE_ENV=test
```

### Result

The pull-request CI workflow runs successfully and validates the application before merge.

---

## 11. Docker Image Security Scanning

### Challenge

The assignment required vulnerability scanning before deployment.

### Resolution

Trivy was added to the GitHub Actions pipeline.

The pipeline scans the built Docker image for:

- CRITICAL vulnerabilities
- HIGH vulnerabilities

Unfixed vulnerabilities are ignored to avoid blocking deployment on vulnerabilities without available upstream fixes.

### Result

Container security is checked before the image is pushed and deployed.

---

## 12. Production Approval

### Challenge

Production deployment needed to require manual approval rather than automatically deploying every change.

### Resolution

A GitHub Environment named:

```text
production
```

was configured with required reviewers.

The production deployment job references that environment.

### Result

The pipeline pauses before production and requires an explicit approval.

---

## 13. Staging and Production Infrastructure

### Challenge

The assignment requires both staging and production deployment, while the project also needs to remain cost-conscious.

Running completely separate AWS environments would increase resource costs.

### Resolution

The workflow separates staging and production logically through GitHub Actions and the production approval gate.

The same EC2 infrastructure is used for the assignment deployment.

### Limitation

For a real production environment, separate staging and production infrastructure should be used to provide stronger isolation and reduce deployment risk.

---

## 14. NAT Gateway Cost

### Challenge

A conventional AWS private-subnet architecture often uses a NAT Gateway so private application instances can access the internet.

However, NAT Gateway has ongoing costs and was not necessary for the assignment's core requirements.

### Resolution

The private application and database subnets were created without a NAT Gateway.

The design uses no default internet route from the private subnets.

### Result

The architecture avoids NAT Gateway charges.

### Trade-off

Applications in the private subnets cannot directly access the public internet through NAT.

For a larger production environment, VPC endpoints and/or NAT architecture should be evaluated based on application requirements.

---

## 15. ALB Target Health

### Challenge

The ALB must determine whether the EC2 application is healthy before forwarding traffic.

### Resolution

An ALB target group was configured with an HTTP health check against:

```text
/
```

on port:

```text
8080
```

### Result

The target becomes healthy when the application responds successfully.

---

## 16. Security Group Design

### Challenge

The application and database should not be directly accessible from the internet.

### Resolution

Separate security groups were created:

```text
Internet
   |
   v
ALB Security Group
   |
   v
Application Security Group
   |
   v
RDS Security Group
```

Rules are scoped by security group relationship:

- ALB accepts HTTP/HTTPS.
- Application accepts port 8080 only from the ALB security group.
- RDS accepts PostgreSQL port 5432 only from the application security group.

### Result

Network access is restricted according to the application flow.

---

## 17. Monitoring Memory and Disk

### Challenge

Basic EC2 CloudWatch monitoring provides CPU metrics, but memory and disk utilization require additional monitoring configuration.

### Resolution

The CloudWatch Agent was configured on the EC2 instance to publish additional system metrics and logs.

### Result

CPU, memory and disk monitoring can be visualized through CloudWatch dashboards.

---

## 18. Centralized Logging

### Challenge

Application and system logs need to be available centrally for troubleshooting instead of requiring manual inspection on EC2.

### Resolution

CloudWatch Logs was configured for centralized log collection.

Relevant application/system logs are sent to CloudWatch log groups.

### Result

Logs can be searched and analyzed from the AWS console.

---

## 19. Monitoring Dashboards

### Challenge

The assignment requires two dashboards covering infrastructure, application and database health.

### Resolution

Two CloudWatch dashboards were created.

### Dashboard 1 – Infrastructure

Includes:

- EC2 CPU
- EC2 memory
- EC2 disk
- ALB requests
- ALB errors

### Dashboard 2 – Application & Database

Includes:

- ALB latency
- ALB 4xx/5xx
- RDS CPU
- RDS connections
- RDS free storage

### Result

The dashboards provide a single place to monitor the deployed system.

---

## 20. Lessons Learned

The implementation reinforced several DevOps practices:

1. Infrastructure should be reproducible through Infrastructure as Code.
2. Secrets should never be stored directly in source code.
3. Short-lived OIDC credentials are preferable to long-lived AWS keys.
4. CI should validate code before deployment.
5. Container images should be security-scanned before release.
6. Deployments should be automated and traceable to a Git commit.
7. Production deployments should have an approval gate.
8. Monitoring and centralized logging should be part of the deployment design.
9. Cost should be considered when selecting AWS architecture.
10. Temporary troubleshooting access should be removed after the issue is resolved.
