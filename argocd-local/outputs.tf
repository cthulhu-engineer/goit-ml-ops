output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_ui_url" {
  description = "ArgoCD UI URL (after port-forward)"
  value       = "http://localhost:8080"
}

output "instructions" {
  description = "Instructions to access ArgoCD"
  value = <<EOT
To access ArgoCD:

1. Get the admin password:
   kubectl get secret argocd-initial-admin-secret -n ${kubernetes_namespace.argocd.metadata[0].name} -o jsonpath="{.data.password}" | base64 --decode

2. Port forward to access UI:
   kubectl port-forward svc/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8080:80

3. Open browser:
   http://localhost:8080

Login: admin
Password: (from step 1)
EOT
}
