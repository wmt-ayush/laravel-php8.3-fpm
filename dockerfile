FROM php:8.3-fpm

# Set timezone to UTC
RUN echo "UTC" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# Update package lists
RUN apt-get update

# Install essential packages
RUN apt-get install -y \
    zip \
    unzip \
    curl \
    nano \
    sqlite3 \
    nginx \
    supervisor \
    git \
    cron \
    jpegoptim \
    pngquant \
    optipng

# Install development dependencies and libraries
RUN apt-get install -y \
    build-essential \
    zlib1g-dev \
    libjpeg-dev \
    libpng-dev \
    libxml2-dev \
    libxslt1-dev \
    libbz2-dev \
    libzip-dev \
    libicu-dev \
    libfreetype6-dev \
    default-mysql-client \
    libmariadb-dev \
    libonig-dev \
    libwebp-dev \
    libavif-dev \
    autoconf \
    pkg-config

# Configure and install PHP extensions
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-avif && \
    docker-php-ext-configure zip && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
    docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo \
    pdo_mysql \
    gd \
    zip \
    intl \
    bz2 \
    opcache \
    sockets \
    pcntl \
    bcmath \
    xml

# Clean up development dependencies to reduce image size
RUN apt-get remove -y \
    build-essential \
    autoconf \
    pkg-config && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify PHP installation
RUN php -v && php -m

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer && \
    composer --version

# Set Composer environment variable and PATH
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

# Copy custom PHP configurations
COPY opcache.ini $PHP_INI_DIR/conf.d/
COPY php.ini $PHP_INI_DIR/conf.d/

# Set up Cron and Supervisor
RUN echo '*  *  *  *  * /usr/local/bin/php /var/www/artisan schedule:run >> /dev/null 2>&1' | crontab - && \
    mkdir -p /etc/supervisor/conf.d && \
    mkdir -p /var/run && \
    chmod 755 /var/run

# Copy configuration files
COPY master.ini /etc/supervisor/conf.d/
COPY default.conf /etc/nginx/sites-available/default
COPY nginx.conf /etc/nginx/

# Enable nginx site and remove default
RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Set working directory
WORKDIR /var/www/

# Set the default command to start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
