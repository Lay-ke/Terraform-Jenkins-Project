output "lb_sg_id" {
  value = aws_security_group.lb.id
}

output "web_sg_id" {
  value = aws_security_group.web.id
}

output "worker_node_sg_id" {
  value = aws_security_group.worker_node.id
}