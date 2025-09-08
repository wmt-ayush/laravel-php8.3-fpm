FROM php:8.4-fpm-alpine

# Set timezone to UTC
RUN echo "UTC" > /etc/timezone

# Install essential packages first
RUN apk add --no-cache \
    zip \
    unzip \
    openrc \
    curl \
    nano \
    sqlite \
    nginx \
    supervisor \
    git

# Install development dependencies and libraries
RUN apk add --no-cache \
    $PHPIZE_DEPS \
    linux-headers \
    zlib-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libxml2 \
    libxslt-dev \
    libxslt \
    bzip2-dev \
    libzip-dev \
    icu-dev \
    icu-libs \
    icu-data-full \
    freetype-dev \
    mysql-client \
    mariadb-client \
    mariadb-connector-c-dev \
    dcron \
    jpegoptim \
    pngquant \
    optipng \
    oniguruma-dev \
    libwebp-dev \
    libavif-dev \
    autoconf \
    g++ \
    make

# Fix for XML extension in PHP 8.4
RUN apk add --no-cache libxml2 libxml2-dev

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

# Install PHP extensions with proper error handling
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
RUN apk del --no-cache \
    $PHPIZE_DEPS \
    autoconf \
    g++ \
    make \
    linux-headers

# Keep only runtime dependencies
RUN apk add --no-cache \
    libxml2 \
    libxslt \
    icu-libs \
    libjpeg-turbo \
    libpng \
    freetype \
    libzip \
    libwebp \
    libavif

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
RUN echo '*  *  *  *  * /usr/local/bin/php /var/www/artisan schedule:run >> /dev/null 2>&1' > /etc/crontabs/root && \
    mkdir -p /etc/supervisor.d

# Copy configuration files
ADD master.ini /etc/supervisor.d/
ADD default.conf /etc/nginx/conf.d/
ADD nginx.conf /etc/nginx/

# Set working directory
WORKDIR /var/www/

# Set the default command to start supervisord
CMD ["/usr/bin/supervisord"]
