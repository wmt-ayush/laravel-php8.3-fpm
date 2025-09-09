# Using Base Ubuntu Image
FROM ubuntu:22.04

LABEL Maintainer="Ayush Chaturvedi <ayushc@webmobtech.com>" \
      Description="Nginx + PHP8.3-FPM Based on Ubuntu 22.04."

# Setup Document Root
RUN mkdir -p /var/www/

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# Base Install
RUN apt update --fix-missing && \
    ln -snf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    echo Asia/Kolkata > /etc/timezone

RUN apt install -y \
      software-properties-common \
      git \
      zip \
      unzip \
      curl \
      ca-certificates \
      lsb-release \
      libicu-dev \
      supervisor \
      nginx \
      nano \
      cron \
      gnupg2

# Add Ondrej PHP Repository for PHP 8.3
RUN add-apt-repository ppa:ondrej/php && \
    apt update -y

# Install PHP 8.3-FPM and extensions
RUN apt install -y \
      php8.3-fpm \
      php8.3-pdo \
      php8.3-mysql \
      php8.3-zip \
      php8.3-gd \
      php8.3-mbstring \
      php8.3-curl \
      php8.3-xml \
      php8.3-bcmath \
      php8.3-intl \
      php8.3-soap \
      php8.3-redis \
      php8.3-imagick \
      php8.3-dev \
      php8.3-cli \
      php8.3-common \
      php8.3-opcache

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/local/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

# Verify Composer installation
RUN composer --version

# Setup CronJobs for Laravel
RUN crontab -l | { cat; echo "* * * * * php /var/www/artisan schedule:run >> /dev/null 2>&1"; } | crontab -

# Configure Custom Nginx and PHP Settings  
RUN rm -f /etc/nginx/sites-enabled/default

# Copy configuration files
COPY php.ini /etc/php/8.3/fpm/php.ini
COPY www.conf /etc/php/8.3/fpm/pool.d/www.conf
COPY default.conf /etc/nginx/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/
COPY horizon.conf /etc/supervisor/conf.d/

# Set proper permissions
RUN chown -R www-data:www-data /var/www && \
    chmod -R 755 /var/www

# Create PHP-FPM run directory
RUN mkdir -p /var/run/php

# Expose port
EXPOSE 80

# Start supervisord
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
