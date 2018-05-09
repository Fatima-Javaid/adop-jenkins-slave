FROM centos:centos7.2.1511
MAINTAINER "Nick Griffin" <nicholas.griffin@accenture.com>

# Java Env Variables
ENV JAVA_VERSION=8u161
ENV JAVA_MAJOR_VERSION=8
ENV JAVA_BUILD_VERSION=b12
ENV JAVA_HASH=2f38c3b165be4555a1fa6e98c45e0808
ENV JAVA_HOME=/usr/java/latest
ENV PATH=$PATH:${JAVA_HOME}/bin

#Terraform Env Variables
ENV TERRAFORM_VERSION=0.11.4

# Swarm Env Variables (defaults)
ENV SWARM_MASTER=http://jenkins:8080/jenkins/
ENV SWARM_USER=jenkins
ENV SWARM_PASSWORD=jenkins

# Slave Env Variables
ENV SLAVE_NAME="Swarm_Slave"
ENV SLAVE_LABELS="docker aws ldap terraform tower nodejs"
ENV SLAVE_MODE="exclusive"
ENV SLAVE_EXECUTORS=2
ENV SLAVE_DESCRIPTION="Core Jenkins Slave"

# Docker versions Env Variables
ENV DOCKER_ENGINE_VERSION=1.10.3-1.el7.centos
ENV DOCKER_COMPOSE_VERSION=1.6.0
ENV DOCKER_MACHINE_VERSION=v0.6.0

#ENV NPM_CONFIG_PREFIX=~/.npm-global
#USER root
#
# Pre-requisites (Including NodeJS)
#yum erase -y nodejs npm && \
#    gcc c++ \
#    make \
#    bzip2 \
#    fontconfig \
#    freetype \

#    #installing nodejs 9.x and upgrading pip to latest
#RUN curl -s -L https://rpm.nodesource.com/setup_9.x | bash
#RUN yum install -y nodejs && \

RUN npm install -g --no-progress requirejs \
@angular/cli@1.3.2 \
tslint \
typescript \
karma \
jasmine \
jasmine-core \
karma-jasmine \
karma-phantomjs-launcher \
karma-htmlfile-reporter \
karma-jasmine-html-reporter \
karma-requirejs \
karma-junit-reporter

RUN yum -y install epel-release
RUN yum update -y && \
yum install -y which \
    git \
    yum-utils \
    wget \
    tar \
    zip \
    unzip \
    openldap-clients \
    openssl \
    python-pip \
    libxslt

#upgrading pip
RUN pip install --upgrade pip
    
# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN mv terraform /usr/local/bin/ && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN terraform --version

# Install AWS CLI
RUN pip install awscli==1.14.3

# Install Ansible
RUN pip install ansible

# Install Tower CLI
RUN pip install ansible-tower-cli

# Install Docker
RUN curl -fsSL https://get.docker.com/ | sed "s/docker-engine/docker-engine-${DOCKER_ENGINE_VERSION}/" | sh

RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
RUN curl -L https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}/docker-machine-`uname -s`-`uname -m` >/usr/local/bin/docker-machine && \
    chmod +x /usr/local/bin/docker-machine

# Install Java
#Using variables
#RUN wget --no-check-certificate --no-cookies --header 'Cookie: oraclelicense=accept-securebackup-cookie' 'http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}-${JAVA_BUILD_VERSION}/${JAVA_HASH}/jdk-${JAVA_VERSION}-linux-x64.rpm' -O /tmp/jdk-${JAVA_MAJOR_VERSION}-linux-x64.rpm
#Not using variables
#RUN wget --no-check-certificate --no-cookies --header 'Cookie: oraclelicense=accept-securebackup-cookie' 'http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.rpm' -O /tmp/jdk-8-linux-x64.rpm
RUN wget --no-cookies \
--no-check-certificate \
--header "Cookie: oraclelicense=accept-securebackup-cookie" \
"http://download.oracle.com/otn-pub/java/jdk/9.0.4+11/c2514751926b4512b076cc82f959763f/jdk-9.0.4_linux-x64_bin.rpm" -O /tmp/jdk-9.0.4_linux-x64_bin.rpm
#Using variables
#RUN yum -y install /tmp/jdk-${JAVA_MAJOR_VERSION}-linux-x64.rpm
#Not using variables
RUN yum -y install /tmp/jdk-9.0.4_linux-x64_bin.rpm

RUN alternatives --install /usr/bin/java jar ${JAVA_HOME}/bin/java 200000
RUN alternatives --install /usr/bin/javaws javaws ${JAVA_HOME}/bin/javaws 200000
RUN alternatives --install /usr/bin/javac javac ${JAVA_HOME}/bin/javac 200000

RUN yum clean all
RUN rm -rf /var/cache/yum && rm -rf /tmp/* && rm -rf /var/log/*

# Make Jenkins a slave by installing swarm-client
RUN curl -s -o /bin/swarm-client.jar -k http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/2.0/swarm-client-2.0-jar-with-dependencies.jar

# Start Swarm-Client
CMD java -jar /bin/swarm-client.jar -executors ${SLAVE_EXECUTORS} -description "${SLAVE_DESCRIPTION}" -master ${SWARM_MASTER} -username ${SWARM_USER} -password ${SWARM_PASSWORD} -name "${SLAVE_NAME}" -labels "${SLAVE_LABELS}" -mode ${SLAVE_MODE}
