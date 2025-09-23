# Use official Nginx image as base
FROM nginx:alpine

# Copy static files to Nginx html directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 (Nginx default, mapped to 3000 by Kubernetes service)
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
