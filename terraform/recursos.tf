# RESOURCE GROUP 
# Contenedor lógico de todos los recursos del proyecto
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "casopractico2"
  }
}

# CLAVE SSH 
# Par de claves SSH generado por Terraform para acceder a la VM
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}



# RED VIRTUAL 
# Red privada donde estará conectada la VM
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-casopractico2"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "casopractico2"
  }
}

# Subred dentro de la red virtual
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-casopractico2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}



# NETWORK SECURITY GROUP 
# Reglas de firewall para controlar el tráfico de entrada a la VM
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-casopractico2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Permitir acceso SSH para administración
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permitir tráfico HTTP
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permitir tráfico HTTPS
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "casopractico2"
  }
}



# IP PÚBLICA 
# Dirección IP accesible desde Internet para el servidor web
resource "azurerm_public_ip" "public_ip" {
  name                = "pip-casopractico2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "casopractico2"
  }
}



# TARJETA DE RED (NIC) 
# Conecta la VM a la subred y a la IP pública
resource "azurerm_network_interface" "nic" {
  name                = "nic-casopractico2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  tags = {
    environment = "casopractico2"
  }
}

# Asociación de la NIC con el NSG
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}



# MÁQUINA VIRTUAL LINUX 
# VM Ubuntu donde se ejecutará el servidor web con Podman
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-casopractico2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2als_v2"
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  # Clave SSH gestionada por Terraform para acceso seguro
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Imagen del sistema operativo: Ubuntu 22.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "casopractico2"
  }
}



#  AZURE CONTAINER REGISTRY 
# Registro privado de imágenes de contenedores
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    environment = "casopractico2"
  }
}



# AZURE KUBERNETES SERVICE 
# Cluster Kubernetes gestionado por Azure
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-casopractico2"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2als_v2"
  }

  # Identidad gestionada por Azure (SystemAssigned)
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "casopractico2"
  }
}

# Permiso para que AKS pueda descargar imágenes del ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}