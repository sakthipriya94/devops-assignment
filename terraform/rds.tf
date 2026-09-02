# -----------------------------
# RDS Subnet Group
# -----------------------------

resource "aws_db_subnet_group" "postgres" {
  name = "devops-postgres-subnet-group"

  subnet_ids = [
    aws_subnet.private_db_1.id,
    aws_subnet.private_db_2.id
  ]

  tags = {
    Name = "devops-postgres-subnet-group"
  }
}


# -----------------------------
# PostgreSQL RDS
# -----------------------------

resource "aws_db_instance" "postgres" {
  identifier = "devops-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "testdb"
  username = "postgres"
  password = var.db_password

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true

  backup_retention_period = 1

  tags = {
    Name = "devops-postgres"
  }
}
