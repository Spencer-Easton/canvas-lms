#!/bin/bash

bash_src_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
canvas_src_path="$( cd $bash_src_path; cd ../../ && pwd )"
echo "Setting up Canvas development environment at: $canvas_src_path"

vboxmanage --version &> /dev/null || { echo >&2 "VirtualBox not installed.  Please install it first"; exit 1; }
vboxmanage list extpacks &> /dev/null || { echo >&2 "VirtualBox Extension pack not installed.  Please install it first"; exit 1; }

if [ "$(uname)" == "Darwin" ]; then
  # OS X platform
  echo "Setting up Docker VM for Mac"

  if ! dinghy version &> /dev/null; then
    echo "Installing dinghy"
    git clone https://github.com/codekitchen/dinghy.git ../dinghy
    if [ $? -ne 0 ]
    then
     echo "Failed cloning dinghy source code"
     exit 1;
    fi
    cd ../dinghy
    brew update || { echo >&2 "Error: brew update failed!"; exit 1; }
    brew tap codekitchen/dinghy
    brew install dinghy
    if [ $? -ne 0 ]
    then
     echo "Failed installing dinghy to $(pwd)"
     exit 1;
    fi
    brew install docker docker-machine || { echo >&2 "Error: brew install docker docker-machine failed!"; exit 1; }

    dingyoutput="$(dinghy create --memory=4096 --cpus=4 --provider=virtualbox)"
    if [ $? -ne 0 ]
    then
     echo "Failed creating dinghy VM: dinghy create --memory=4096 --cpus=4 --provider=virtualbox"
     exit 1;
    fi

    # TODO!!! grab the ENV variables output by dinghy create and add them to .bashrc
    # e.g. 
    # export DOCKER_HOST=tcp://192.168.99.100:2376
    # export DOCKER_CERT_PATH=/Users/sadleb/.docker/machine/machines/dinghy
    # export DOCKER_TLS_VERIFY=1
    # export DOCKER_MACHINE_NAME=dinghy

    read response $'Please add the above ENV variables to your ~/.bashrc and hit Enter'
    source ~/.bashrc

    echo "Installed dinghy to $(pwd)"
  fi

  dinghy up || { echo >&2 "Error: dinghy up failed."; exit 1; }
  docker ps &> /dev/null || { echo >&2 "Error: somethings wrong with docker.  Make sure this command lists your containers: docker ps"; exit 1; }

  if ! docker-compose --version &> /dev/null; then
    echo "Installing docker-compose"
    brew install docker-compose --without-boot2docker || { echo >&2 "Error: brew install docker-compose --without-boot2docker failed!"; exit 1; }
  fi

  if [ -z $CANVAS_SRC_PATH ]
  then
    echo "export CANVAS_SRC_PATH=$canvas_src_path" >> ~/.bashrc
    source ~/.bashrc
  fi

  cd $canvas_src_path
  cp -a docker-compose/config/* config/
  docker-compose build --no-cache || { echo >&2 "Error: docker-compose build --no-cache failed."; exit 1; }
  docker-compose up  || { echo >&2 "Error: docker-compose up failed."; exit 1; }
  docker-compose run --rm web /bin/bash eval "bundle install; npm install; bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:initial_setup; bundle exec rake canvas:compile_assets"
  if [ $? -ne 0 ]
  then
     echo "Error: docker-compose run --rm web /bin/bash failed to run and configure the containers."
     exit 1;
  fi
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  # GNU/Linux platform
  echo "ERROR: setup script not written for Linux.  Please write it!"
  exit 1;
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
  # Windows NT platform
  echo "ERROR: setup script not written for Windows.  Please write it!"
  exit 1;
fi

echo "Setup complete!  Please start a new shell to get your environment variables"
