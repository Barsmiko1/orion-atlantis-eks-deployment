output "atlantis_url" {
  description = "The URL of the Atlantis service"
  value       = "http://${data.kubernetes_service.atlantis.status[0].load_balancer[0].ingress[0].hostname}"
}
