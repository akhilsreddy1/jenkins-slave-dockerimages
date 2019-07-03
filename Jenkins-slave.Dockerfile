FROM jenkins/jnlp-slave

USER root

ENV MAVEN_VERSION=3.6.1
ENV NODE_VERSION 10.9.0
ENV MAVEN_HOME /usr/share/maven
ENV HOME /home/jenkins

LABEL Description="Extending Jenkins agent executable (slave.jar) for building projects using Maven / Angular"

# Install necessary Packages
RUN apt-get update && apt-get upgrade -yq && apt-get install -yq git openssh-client --no-install-recommends vim apt-transport-https \
    ca-certificates curl wget software-properties-common apt-utils locales libapr1 openssl libtcnative-1 bash python3 python3-pip

# Add Docker repos
RUN curl -k -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
    
RUN apt-get update && apt-get install -yq docker-ce
    
# Install envsubst
RUN apt-get install -y gettext

# Install Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Install helm
# RUN curl -k -L https://git.io/get_helm.sh | bash

# Install maven 

RUN curl -k -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
    && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# Copy TU settings.xml 
ADD maven_settings.xml $MAVEN_HOME/conf/settings.xml
 
# Add  chrome for protractor tests
RUN wget --no-check-certificate -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

# Install Node 
RUN mkdir /usr/lib/nodejs \
    && curl -k -fsSL "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" | tar xz --directory "/usr/lib/nodejs" \
    && mv /usr/lib/nodejs/node-v$NODE_VERSION-linux-x64 /usr/lib/nodejs/node

# Globalconfig to TU Artifactory and Token
ADD npmrc /usr/lib/nodejs/node/etc/npmrc

# Set PATH
ENV NODEJS_HOME="/usr/lib/nodejs/node"
#ENV NPM_PACKAGES="${HOME}/.npm-packages"
ENV PATH="$NODEJS_HOME/bin:$PATH"

RUN npm install -g @angular/cli --unsafe
 
# Install Ansible 

RUN apt-get install -yq ansible

RUN echo "==> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]