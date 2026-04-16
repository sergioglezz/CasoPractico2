# 🚀 Caso Práctico 2 — Automatización de despliegues en Azure

> **UNIR · DevOps & Cloud** — Automatización completa de infraestructura cloud con Terraform y Ansible

[![Terraform](https://img.shields.io/badge/Terraform-3.x-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.x-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Azure](https://img.shields.io/badge/Microsoft_Azure-spaincentral-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/AKS-1_nodo-326CE5?logo=kubernetes&logoColor=white)](https://azure.microsoft.com/en-us/products/kubernetes-service)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

---

## 📋 Descripción

Despliegue **completamente automatizado** de una infraestructura en Microsoft Azure: desde cero hasta tener una aplicación funcionando en Kubernetes, sin ningún paso manual. Cada recurso, cada configuración y cada despliegue está definido en código y es 100% reproducible.

### Stack tecnológico

| Herramienta | Rol |
|---|---|
| **Terraform** | Provisión de infraestructura en Azure (IaC) |
| **Ansible** | Configuración de servidores y despliegue de aplicaciones |
| **Podman** | Ejecución de contenedores en la VM |
| **Azure Kubernetes Service (AKS)** | Orquestación de contenedores |
| **Azure Container Registry (ACR)** | Registro privado de imágenes |

---

## 🏗️ Arquitectura

```
Internet
    │
    ├──── HTTP/HTTPS ────► VM Ubuntu 22.04 (Standard_B2als_v2)
    │                          └── Podman
    │                               └── Nginx (SSL + htpasswd)
    │                          IP pública: 68.221.201.59
    │
    └──── TCP 6379 ──────► AKS Cluster (1 worker node)
                               └── Namespace: casopractico2
                                    ├── Pod Redis 6.0.8
                                    │    └── PersistentVolumeClaim 1GB
                                    ├── Service ClusterIP (interno)
                                    └── LoadBalancer (70.156.226.112)

                     ACR: acrsergioglezzcp2.azurecr.io
                          ├── webserver/nginx:casopractico2
                          └── app/redis:casopractico2
```

Todos los recursos se despliegan en el **Resource Group `rg-casopractico2`** en la región `spaincentral`, etiquetados con `environment=casopractico2`.

---

## 📁 Estructura del repositorio

```
CasoPractico2/
├── terraform/
│   ├── main.tf          # Proveedor Azure + configuración Terraform
│   ├── vars.tf          # Variables parametrizadas
│   ├── recursos.tf      # Definición de todos los recursos Azure
│   └── outputs.tf       # Valores de salida (IP, credenciales ACR, etc.)
│
└── ansible/
    ├── playbook.yml     # Playbook principal (orquesta los 3 roles)
    ├── hosts            # Inventario (VM remota + localhost)
    ├── ansible.cfg      # Configuración general de Ansible
    ├── secrets.yml      # Credenciales sensibles (en .gitignore)
    └── roles/
        ├── acr/
        │   └── tasks/main.yml   # Gestión de imágenes en el ACR
        ├── vm/
        │   └── tasks/main.yml   # Instalación Podman + despliegue nginx
        └── aks/
            └── tasks/main.yml   # Despliegue Redis en Kubernetes
```

---

## ☁️ Infraestructura con Terraform

### Recursos creados (12 en total)

| Recurso | Nombre | Descripción |
|---|---|---|
| Resource Group | `rg-casopractico2` | Contenedor de todos los recursos |
| Virtual Network | `vnet-casopractico2` | Red privada `10.0.0.0/16` |
| Subnet | `subnet-casopractico2` | Subred `10.0.1.0/24` |
| Network Security Group | `nsg-casopractico2` | Firewall: puertos 22, 80, 443 |
| Public IP | `pip-casopractico2` | IP estática Standard SKU |
| Network Interface | `nic-casopractico2` | Tarjeta de red de la VM |
| Virtual Machine | `vm-casopractico2` | Ubuntu 22.04 LTS, Standard_B2als_v2 |
| TLS Private Key | — | Clave SSH generada automáticamente |
| Container Registry | `acrsergioglezzcp2` | ACR Basic SKU, admin habilitado |
| AKS Cluster | `aks-casopractico2` | 1 nodo worker, identidad SystemAssigned |
| Role Assignment | — | Permiso AcrPull del AKS sobre el ACR |

### Comandos

```bash
cd terraform/

# Inicializar providers
terraform init

# Revisar el plan de ejecución
terraform plan

# Aplicar la infraestructura
terraform apply

# Destruir todos los recursos
terraform destroy
```

---

## 🤖 Configuración con Ansible

Ansible orquesta tres roles en orden secuencial con un único comando:

```bash
cd ansible/
ansible-playbook -i hosts playbook.yml
```

### Rol ACR
Gestiona las imágenes del registro privado:
1. Login en el ACR con credenciales de Azure
2. Pull de `nginx:latest` desde Docker Hub
3. Tag y push → `acrsergioglezzcp2.azurecr.io/webserver/nginx:casopractico2`
4. Pull de `redis:6.0.8` desde Docker Hub
5. Tag y push → `acrsergioglezzcp2.azurecr.io/app/redis:casopractico2`

```bash
# Ejecutar solo el rol ACR
ansible-playbook -i hosts playbook.yml --limit acr
```

### Rol VM
Configura la máquina virtual y despliega el servidor web:
1. Actualización de repositorios apt
2. Instalación de Podman
3. Login en el ACR desde la VM
4. Pull de la imagen nginx personalizada desde el ACR
5. Arranque del contenedor con `restart_policy: always`
6. Registro como servicio systemd (`container-webserver`)

```bash
# Ejecutar solo el rol VM
ansible-playbook -i hosts playbook.yml --limit vm
```

### Rol AKS
Despliega Redis con persistencia en Kubernetes:
1. Creación del namespace `casopractico2`
2. Secret para autenticación en el ACR
3. `PersistentVolumeClaim` de 1GB para los datos de Redis
4. `Deployment` de Redis 6.0.8
5. `Service ClusterIP` para comunicación interna entre pods
6. `Service LoadBalancer` para exposición al exterior

```bash
# Ejecutar solo el rol AKS
ansible-playbook -i hosts playbook.yml --limit aks
```

---

## 🌐 Aplicaciones desplegadas

### Servidor web Nginx (VM)
- **URL**: `https://68.221.201.59`
- Imagen personalizada con Dockerfile: SSL autofirmado (OpenSSL) + autenticación básica (htpasswd, usuario: `admin`)
- Redirección automática HTTP → HTTPS
- Se reinicia automáticamente con la VM vía systemd

### Redis en AKS
- **IP externa**: `70.156.226.112:6379` (LoadBalancer)
- **IP interna**: `10.0.224.20:6379` (ClusterIP)
- Almacenamiento persistente de 1GB (los datos sobreviven reinicios del pod)

---

## ⚙️ Requisitos previos

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.x`
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) `>= 2.x` con la colección `containers.podman` y `kubernetes.core`
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) autenticado (`az login`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configurado para el cluster AKS
- [Podman](https://podman.io/docs/installation) instalado en local (para el rol ACR)

### Instalar colecciones de Ansible

```bash
ansible-galaxy collection install containers.podman
ansible-galaxy collection install kubernetes.core
```

### Configurar credenciales

Crear el fichero `ansible/secrets.yml` con:

```yaml
acr_password: "<password_del_ACR>"
```

> ⚠️ Este fichero está en `.gitignore` y nunca debe subirse al repositorio.

---

## 🐛 Problemas conocidos y soluciones

| Problema | Causa | Solución |
|---|---|---|
| Error 403 en `terraform apply` | Región `westeurope` no permitida en suscripción de estudiante | Usar `spaincentral` en `vars.tf` |
| Nombre ACR ya en uso | Los nombres de ACR son únicos globalmente | Usar un nombre personalizado (ej. `acrsergioglezzcp2`) |
| Tamaño de VM no disponible | `Standard_B2s` no disponible en `spaincentral` | Usar `Standard_B2als_v2` |
| IP pública Basic no permitida | SKU Basic no permitido en `spaincentral` | Cambiar a SKU `Standard` |
| Error `short-name` en Podman | Sin registros de búsqueda definidos en WSL2 | Añadir `unqualified-search-registries = ["docker.io"]` en `/etc/containers/registries.conf` |
| Ansible no actualiza la imagen | El contenedor ya existía y no se recreaba | Forzar `podman stop`, `podman rm` y `podman run` manualmente o usar `recreate: true` |

---

## 📄 Licencia

Este proyecto se distribuye bajo la licencia **MIT**. Consulta el fichero [LICENSE](./LICENSE) para más detalles.

---

## 📚 Referencias

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/)
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Podman Documentation](https://docs.podman.io/en/latest/)
- [Ansible Documentation](https://docs.ansible.com/)
- [containers.podman collection](https://galaxy.ansible.com/ui/repo/published/containers/podman/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
