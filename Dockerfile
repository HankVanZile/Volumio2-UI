FROM node:10.22.1-buster

# Set repository URL as a build argument with a default value
ARG GIT_REPO_URL=https://github.com/HankVanZile/Volumio2-UI.git
ARG GIT_BRANCH=master

# Install essential packages
RUN apt-get update && apt-get install -y \
    openssh-server \
    git \
    curl \
    wget \
    vim \
    nano \
    build-essential \
    python \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Setup SSH
RUN mkdir /var/run/sshd
RUN echo 'root:password' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise, user gets kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Set Chrome environment variables for Karma
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMIUM_BIN=/usr/bin/chromium

# Install global npm tools
RUN npm install -g bower gulp@3.9.1 

# Set working directory
WORKDIR /app

# Clone the repository and install dependencies
RUN git clone --branch ${GIT_BRANCH} ${GIT_REPO_URL} /app && \
npm install --unsafe-perm && \
bower install

# Set environment variables
ENV NODE_ENV=development
ENV PATH=$PATH:/app/node_modules/.bin

# Expose ports for the application and SSH
EXPOSE 3000 22

# Create a start script
RUN echo '#!/bin/bash\n\
service ssh start\n\
echo "Repository cloned from: ${GIT_REPO_URL} (branch: ${GIT_BRANCH})"\n\
echo "You can update the repo with: git pull"\n\
exec "$@"\n'\
> /start.sh && chmod +x /start.sh

# Set entry point
ENTRYPOINT ["/start.sh"]

# Default command to keep container running
CMD ["tail", "-f", "/dev/null"]
