# A lightweight web server
FROM nginx:alpine

# Copy the HTML files into Nginx's public directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80
