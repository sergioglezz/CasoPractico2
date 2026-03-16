# ID de la suscripción de Azure
variable "subscription_id" {
  description = "ID de la suscripción de Azure del estudiante"
  type        = string
  default     = "5d08c111-a032-4281-a38e-822b6a4fd7db"
}

# Región de Azure donde se crearán todos los recursos
variable "location" {
  description = "Región de Azure para el despliegue"
  type        = string
  default     = "spaincentral"
}

# Nombre del grupo de recursos que contendrá toda la infraestructura
variable "resource_group_name" {
  description = "Nombre del Resource Group del proyecto"
  type        = string
  default     = "rg-casopractico2"
}

# Nombre del ACR — debe ser único globalmente en Azure, solo letras y números
variable "acr_name" {
  description = "Nombre único del Azure Container Registry"
  type        = string
  default     = "acrsergioglezzcp2"
}

# Nombre del cluster AKS
variable "aks_name" {
  description = "Nombre del cluster Azure Kubernetes Service"
  type        = string
  default     = "aks-casopractico2"
}

# Usuario administrador de la VM Linux
variable "admin_username" {
  description = "Nombre del usuario administrador de la máquina virtual"
  type        = string
  default     = "azureuser"
}