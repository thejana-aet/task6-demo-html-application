# Use a lightweight web server
FROM nginx:alpine

# Copy your HTML files into Nginx's public directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80
