output "alb-dns-name" {
  value = aws_lb.load_balancer.dns_name
  description = "DNS name of the ALB"
}