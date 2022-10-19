output "region_1" {
    value = data.aws_ami.ubuntu_region_1.availability_zone
    description = "The name of the first region"
}

output "region_2" {
    value = data.aws_ami.ubuntu_region_2.availability_zone
    description = "The name of the second region"
}