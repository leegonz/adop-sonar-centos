FROM centos-openjdk-8

ARG user=sonarqube
ARG group=sonarqube
ARG uid=1001
ARG gid=1001

# SonarQube installation copied from SonarQube official Github repo
ENV SONAR_VERSION=6.3 \
    SONARQUBE_HOME=/opt/sonarqube \
    # Database configuration
    # Defaults to using H2
    SONARQUBE_JDBC_USERNAME=sonar \
    SONARQUBE_JDBC_PASSWORD=sonar \
    SONARQUBE_JDBC_URL= \
    SONARQUBE_WEB_CONTEXT=/ \
    SONARQUBE_SERVER_BASE="http://localhost:9000" \
    SONARQUBE_WEB_CONTEXT="/sonar" \
    SONARQUBE_FORCE_AUTHENTICATION=true \
    ADOP_LDAP_ENABLED=true \
    SONARQUBE_JMX_ENABLED=false

RUN groupadd -g ${gid} ${group} \
    && useradd ${user} -u ${uid} -g ${group}

# Http port
EXPOSE 9000

RUN set -x \
    # pub   2048R/D26468DE 2015-05-25
    #       Key fingerprint = F118 2E81 C792 9289 21DB  CAB4 CFCA 4A29 D264 68DE
    # uid                  sonarsource_deployer (Sonarsource Deployer) <infra@sonarsource.com>
    # sub   2048R/06855C1D 2015-05-25
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE \
    && cd /opt \
    && curl -o sonarqube.zip -fSL https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip \
    && curl -o sonarqube.zip.asc -fSL https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip.asc \
    && gpg --batch --verify sonarqube.zip.asc sonarqube.zip \
    && unzip sonarqube.zip \
    && mv sonarqube-$SONAR_VERSION sonarqube \
    && rm sonarqube.zip* \
    && rm -rf $SONARQUBE_HOME/bin/*

WORKDIR $SONARQUBE_HOME
COPY resources/run.sh $SONARQUBE_HOME/bin/
RUN chmod +x $SONARQUBE_HOME/bin/run.sh

# Custom SonarQube plugins installation hack
ENV SONARQUBE_PLUGINS_DIR=/opt/sonarqube/default/extensions/plugins
COPY resources/plugins.txt ${SONARQUBE_PLUGINS_DIR}/
COPY resources/container-entrypoint resources/plugins.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/*
RUN /usr/local/bin/plugins.sh ${SONARQUBE_PLUGINS_DIR}/plugins.txt

RUN chown -R ${user}. /opt
USER ${user}

ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
