# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# ------------------------------------------------------------------------------
# Pull base image.
FROM ubuntu:16.04
MAINTAINER Yuki Tsuchida(gahaku) <d@gahaku.tech>
# ------------------------------------------------------------------------------
# Install base
RUN apt-get update &&\
    apt-get install -y sudo locales build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs supervisor libgmp3-dev libreadline-dev libpam-cracklib libpq-dev sqlite3 libsqlite3-dev lsof&& \
    sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf&&\
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
# ------------------------------------------------------------------------------
# Add users
RUN useradd -G sudo -m -s /bin/bash lit_users&&\
    echo "lit_users ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/lit_users&&\
    echo 'root:kana.kobayashi' | chpasswd
USER lit_users


# Security changes
RUN sudo update-rc.d supervisor defaults&&\
    sudo ln -s /lib/x86_64-linux-gnu/security/pam_cracklib.so /lib/security

# ------------------------------------------------------------------------------
# Install Ruby2.5.1
RUN git clone https://github.com/sstephenson/rbenv.git /home/lit_users/.rbenv&&\
    git clone https://github.com/sstephenson/ruby-build.git /home/lit_users/.rbenv/plugins/ruby-build

ENV PATH /home/lit_users/.rbenv/bin:$PATH
RUN echo "eval '$(rbenv init -)'" >> /home/lit_users/.profile&&\
    . /home/lit_users/.profile&&\
    rbenv install 2.3.7&&\
    rbenv global 2.3.7

# ------------------------------------------------------------------------------
# Install Node.js
RUN sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -&&\
    sudo apt-get install -y nodejs


# ------------------------------------------------------------------------------
# Install Cloud9
RUN git clone https://github.com/c9/core.git /home/lit_users/cloud9
WORKDIR /home/lit_users/cloud9
RUN scripts/install-sdk.sh&&\
    sed -i -e 's_127.0.0.1_0.0.0.0_g' /home/lit_users/cloud9/configs/standalone.js

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 4567
EXPOSE 8080

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /home/lit_users/workspace
VOLUME /home/lit_users/workspace
WORKDIR /home/lit_users/workspace


RUN sudo curl -L https://raw.githubusercontent.com/c9/install/master/install.sh | sudo bash

RUN sudo apt-get install wget&&\
    curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["sudo","supervisord", "-c", "/etc/supervisor/supervisord.conf"]
