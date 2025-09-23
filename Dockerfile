# Use official Nginx image as base
FROM nginx:alpine

# Copy dist folder to Nginx html directory
COPY dist/ /usr/share/nginx/html/

# Expose port 80 (mapped to 3000 by Kubernetes service)
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
