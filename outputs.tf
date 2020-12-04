# Output values
output "cloudhsm_cluster_id" {
  value = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
}

output "cloudhsm_cluster_state" {
  value = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_state
}

output "cloudhsm_cluster_csr" {
  value = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_state == "UNINITIALIZED" ? aws_cloudhsm_v2_cluster.hsm_cluster.cluster_certificates.0.cluster_csr : null
}

output "cloudhsm_cluster_hsm_ip" {
  value = aws_cloudhsm_v2_hsm.hsm.ip_address
}

output "cloudhsm_cluster_hsm_state" {
  value = aws_cloudhsm_v2_hsm.hsm.hsm_state
}

output "hsm_client_hostname" {
  value = aws_instance.hsm_client.public_dns
}
