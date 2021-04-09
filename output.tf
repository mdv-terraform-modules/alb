output "target_groups_arn" {
  value = aws_lb_target_group.tgs[*].arn
}

output "target_groups_details" {
  value = {
    for i in aws_lb_target_group.tgs :
    i.name => i.arn
  }
}

output "user_data" {
  value = var.user_data
}

output "domain_name" {
  value = var.domain_name
}

output "dns_name" {
  value = aws_lb.lb.dns_name
}

output "zone_id" {
  value = aws_lb.lb.zone_id
}
