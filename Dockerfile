# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# ------------------------------------------------------------------------------
# Pull base image.
FROM ubuntu:16.04
MAINTAINER Yuki Tsuchida(gahaku) <d@gahaku.tech>

# ------------------------------------------------------------------------------
# Install base
RUN apt-get update
RUN apt-get install -y sudo build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs supervisor libreadline-dev libpam-cracklib libpq-dev libsqlite3-dev && \
  sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf
  
# ------------------------------------------------------------------------------
# Add users
RUN useradd -G sudo -m -s /bin/bash lit_users
RUN echo "lit_users ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/lit_users
RUN echo 'root:kana.kobayashi' | chpasswd
USER lit_users


# Security changes
# - Determine runlevel and services at startup [BOOT-5180]
RUN sudo update-rc.d supervisor defaults

# - Install a PAM module for password strength testing like pam_cracklib or pam_passwdqc [AUTH-9262]
RUN sudo ln -s /lib/x86_64-linux-gnu/security/pam_cracklib.so /lib/security

# ------------------------------------------------------------------------------
# Install Ruby2.5.1
RUN git clone https://github.com/sstephenson/rbenv.git /home/lit_users/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /home/lit_users/.rbenv/plugins/ruby-build

ENV PATH /home/lit_users/.rbenv/bin:$PATH
RUN echo "eval '$(rbenv init -)'" >> /home/lit_users/.profile
RUN . /home/lit_users/.profile 
RUN rbenv install 2.5.1

RUN rbenv global 2.5.1

# ------------------------------------------------------------------------------
# Install Node.js
RUN sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
RUN sudo apt-get install -y nodejs


# ------------------------------------------------------------------------------
# Install Cloud9
RUN git clone https://github.com/c9/core.git /home/lit_users/cloud9
WORKDIR /home/lit_users/cloud9
RUN scripts/install-sdk.sh


# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /home/lit_users/cloud9/configs/standalone.js 

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 80
EXPOSE 3000
EXPOSE 4567

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /home/lit_users/workspace
VOLUME /home/lit_users/workspace
WORKDIR /home/lit_users/workspace


RUN sudo curl -L https://raw.githubusercontent.com/c9/install/master/install.sh | sudo bash

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["sudo","supervisord", "-c", "/etc/supervisor/supervisord.conf"]
