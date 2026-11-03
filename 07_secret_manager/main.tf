provider "aws" {
    region = "ap-southeast-1"
}

#1. Create a random password 16-words length, which not have illegal words of RDS
resource "random_password" "db_password" {
    length = 16
    special = true  
    override_special = "!#%^&*()-_=+" #Saved words for MySQL
}

#2. Create a secret box on AWS
resource "aws_secretsmanager_secret" "rds_secret" {
    name = "lab7/rds/mysql-admin-password"
    description = "Master password for Lab6 RDS"
}

#3. Open secret box and take the random password which just created recently into the secret box
resource "aws_secretsmanager_secret_version" "rds_server_version" {
    secret_id = aws_secretsmanager_secret.rds_secret.id
    secret_string = random_password.db_password.result   
}

#4. Display ID of the secret box (w/o passwords) and only use for another Labs
output "secret_arn" {
    value = aws_secretsmanager_secret.rds_secret.arn
}