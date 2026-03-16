# IP pública de la VM para usarla en el inventario de Ansible
output "vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

# URL del servidor de login del ACR
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

# Usuario de administración del ACR
output "acr_admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

# Contraseña del ACR — marcada como sensible, no se muestra en pantalla
output "acr_admin_password" {
  value     = azurerm_container_registry.acr.admin_password
  sensitive = true
}

# Clave SSH privada para acceder a la VM — marcada como sensible
output "ssh_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}