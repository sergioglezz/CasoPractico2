FROM docker.io/library/nginx:latest

# Instalar openssl y apache2-utils para htpasswd
RUN apt-get update && apt-get install -y openssl apache2-utils && rm -rf /var/lib/apt/lists/*

# Crear certificado SSL autofirmado
RUN mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/server.key \
    -out /etc/nginx/certs/server.crt \
    -subj "/C=ES/ST=Cadiz/L=Algeciras/O=UNIR/CN=casopractico2"

# Crear usuario con autenticación básica (usuario: admin, password: casopractico2)
RUN htpasswd -cb /etc/nginx/.htpasswd admin casopractico2

# Copiar configuración nginx personalizada
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Contenido web personalizado
RUN echo "<html><body><h1>Caso Practico 2 - Sergio</h1><p>Servidor web desplegado con Podman sobre Azure VM</p></body></html>" > /usr/share/nginx/html/index.html

EXPOSE 80 443