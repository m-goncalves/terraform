output "lb_dns_name" {
      value = module.webserver_cluster.alb_dns_name
    }

output "asg_name" {
        value = module.webserver_cluster.asg_name
}