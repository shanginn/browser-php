FROM i386/debian:bullseye-slim

ARG PHP_VERSION=8.1

ENV DEBIAN_FRONTEND noninteractive

RUN \
    apt-get -q update && \
    apt-get -y install apt-transport-https lsb-release ca-certificates curl && \
    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg && \
    sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' && \
    apt-get update && \
    apt-get -y install \
        linux-image-686 net-tools grub2 systemd wget iproute2 dhcpcd5 \
        php${PHP_VERSION} \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-bz2 \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-dba \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-memcache \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-uuid \
        php${PHP_VERSION}-yaml \
        && apt-get clean

RUN wget https://psysh.org/psysh -O /usr/local/bin/psysh && chmod +x /usr/local/bin/psysh
RUN mkdir -p ~/.config/psysh/

COPY config/psysh-config.php /root/.config/psysh/config.php

COPY config/getty-noclear.conf config/getty-override.conf /etc/systemd/system/getty@tty1.service.d/
COPY config/getty-autologin-serial.conf /etc/systemd/system/serial-getty@ttyS0.service.d/
COPY config/logind.conf /etc/systemd/logind.conf
COPY config/xorg.conf /etc/X11/
COPY config/networking.sh /root/
COPY config/boot-9p /etc/initramfs-tools/scripts/boot-9p

RUN printf '%s\n' 9p 9pnet 9pnet_virtio virtio virtio_ring virtio_pci | tee -a /etc/initramfs-tools/modules && \
    echo 'BOOT=boot-9p' | tee -a /etc/initramfs-tools/initramfs.conf && \
    update-initramfs -u