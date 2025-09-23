# Use official Nginx image as base
FROM nginx:alpine

# Copy static files to Nginx html dir
COPY . /usr/share/nginx/html

# Expose port 3000 (as per requirement; Nginx default is 80, but we'll map)
EXPOSE 3000

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
