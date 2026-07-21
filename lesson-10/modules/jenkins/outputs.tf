output "jenkins_url_command" {
  value = "kubectl -n ${var.namespace} get svc jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
output "admin_password_command" {
  value = "kubectl -n ${var.namespace} get secret jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d; echo"
}
