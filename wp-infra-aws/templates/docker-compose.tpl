 version: "3.9"
        services:
        wordpress:
            image: wordpress:latest
            restart: always
            environment:
                - WORDPRESS_DB_HOST=${db_host}
                - WORDPRESS_DB_USER=${db_user}
                - WORDPRESS_DB_PASSWORD=${db_password}
                - WORDPRESS_DB_NAME=${db_name}
        nginx:
            depends_on:
                - wordpress
            image: nginx:1.18-alpine
            restart: always
            command: "/bin/sh -c" 'nginx -s reload -g'\"daemon off;\""
            ports:
                - "${external_port}:80"
            volumes:
                - ./nginx:/etc/nginx/conf.d