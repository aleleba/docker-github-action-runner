# base
FROM ubuntu:22.04

# Update Package
RUN apt-get update
# Install apt-utils
RUN apt-get install -y --no-install-recommends apt-utils
# Install Sudo
RUN apt-get -y install sudo
# Install Curl
RUN apt-get -y install curl
# Install VIM
RUN apt-get -y install vim

# set the github runner version
ARG RUNNER_VERSION="2.311.0"

# update the base packages, add a non-sudo user, and install Xvfb
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb && \
    useradd -m docker && \
    echo 'docker ALL=(ALL) NOPASSWD:ALL' | tee -a /etc/sudoers

#Installing Docker
# Let's start with some basic stuff.
RUN sudo apt-get update -qq && sudo apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl \
    lxc \
    iptables   
# Install Docker from Docker Inc. repositories.
RUN curl -sSL https://get.docker.com/ | sh
# Define additional metadata for our image.
VOLUME /var/lib/docker
#RUN sudo usermod -aG docker docker
#Finishing Installing Docker

# install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# copy over the start.sh script
COPY start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# Install the magic wrapper.
ADD ./wrapdocker.sh /usr/local/bin/wrapdocker.sh
RUN sudo chmod +x /usr/local/bin/wrapdocker.sh
RUN sudo sed -i "2 i\exec sudo /usr/local/bin/wrapdocker.sh &" start.sh

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]