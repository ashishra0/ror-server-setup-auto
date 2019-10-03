#!/bin/bash

API_ONLY=$1
# Run as Sudo
if [ $EUID != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

IP=$(curl ifconfig.me -y)
sudo ssh -o ServerAliveCountMax=2 root@$IP
sudo ssh -o ServerAliveInterval=120 root@$IP
echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config

sudo service ssh restart

# Install VIM
sudo apt-get install vim

# Create a Deploy User Optional
# adduser deploy
# adduser deploy sudo
# sudo su deploy
cd ~
echo 'gem: --no-ri --no-rdoc' >> ~/.gemrc

# No need to run this if you are deploying API only applications
if [ -z "$API_ONLY"] && [! $API_ONLY == "api"] ; then
  # Adding Node.js 10 repository
  curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -

  # Adding Yarn repository
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list --sk
  sudo add-apt-repository ppa:chris-lea/redis-server
  # Refresh our packages list with the new repositories

  sudo apt-get update -y
  # Install our dependencies for compiiling Ruby along with Node.js and Yarn
  sudo apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev dirmngr gnupg apt-transport-https ca-certificates redis-server redis-tools nodejs yarn
fi

# Setup & Install Ruby Manager & Ruby
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
git clone https://github.com/rbenv/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars
. ~/.bashrc
rbenv install 2.6.3
rbenv global 2.6.3
ruby -v

# This installs the latest Bundler, currently 2.x.
gem install bundler --no-ri --no-rdoc -V
# For older apps that require Bundler 1.x, you can install it as well.
gem install bundler -v 1.17.3 --no-ri --no-rdoc -V
# Test and make sure bundler is installed correctly, you should see a version number.
bundle -v
# Bundler version 2.0
rbenv rehash

# Installing Nginx
sudo apt update -y
sudo apt install nginx -y
sudo ufw app list
sudo ufw allow 'Nginx HTTP'
sudo ufw status

# sudo ln -nfs /opt/appname/current/config/production.nginx.conf /etc/nginx/sites-available/my-app 
# sudo ln -nfs /etc/nginx/sites-enabled/my-app /etc/nginx/sites-available/my-app
sudo service nginx restart

sudo systemctl status nginx
