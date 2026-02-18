output "vpc_id" {
  value = aws_vpc.snapshot_vpc.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "lambda_function_name" {
  value = aws_lambda_function.snapshot_cleanup.function_name
}

