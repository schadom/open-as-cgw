FROM ubuntu

# build packages
RUN apt-get update \
    && apt-get -y -q install dpkg-dev debhelper fakeroot git \
    && apt-get install -y redis-server \
    && mkdir -p /tmp/build/open-as-cgw \
    && cd /tmp/build/open-as-cgw/ \
    && git clone https://github.com/open-as-team/open-as-cgw \
    && dpkg-buildpackage -rfakeroot \
    && echo "debconf debconf/frontend select noninteractive" | sudo debconf-set-selections \
    && echo "mysql-server mysql-server/root_password password" | sudo debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password" | sudo debconf-set-selections \
    && echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections \
    && echo "postfix postfix/mailname string antispam.localdomain" | sudo debconf-set-selections \
    && sudo apt-get -y -q -f install /tmp/build/*.deb \
    && sudo apt-get -y -q clean \
    && sudo service openas-firewall stop \
    && sudo rm -rf /tmp/build

# configure container entrypoint
COPY entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh
WORKDIR /usr/local/bin
USER root

# expose ports
EXPOSE 25/tcp
EXPOSE 587/tcp
EXPOSE 443/tcp

# run
ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "/bin/bash" ]
