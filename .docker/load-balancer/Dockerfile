FROM nginx

MAINTAINER Chris Leathley <cleathley@thebrandagency.co>

# Install some helpers in the very basic nginx image
RUN apt-get update && \
    apt-get install -y vim procps ca-certificates

# Generate a strong key exchange certificate and self signed SSL for 'localhost'
RUN openssl dhparam -out /etc/nginx/dhparams.pem 2048 && \
    openssl req -subj '/CN=localhost' -x509 -newkey rsa:4096 -nodes -keyout /etc/nginx/localhost.key -out /etc/nginx/localhost.pem -days 999

# Copy the configuration file from the current directory and paste
# it inside the container to use it as Nginx's default config.
COPY nginx.default.conf /etc/nginx/nginx.conf

# Port 80 of the container will be exposed and then mapped to port
# 81 of our host machine via Compose. This way we'll be able to
# access the server via http://localhost:81 (or https://localhost for SSL) on our host.
EXPOSE 80 443

# Start Nginx when the container has provisioned.
CMD ["nginx", "-g", "daemon off;"]

