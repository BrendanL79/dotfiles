#!/bin/bash

. /etc/lsb-release 

apt-add-list() {
  sourcesDir='/etc/apt/sources.list.d'
  if [ ! -f $sourcesDir/$1.list ]
  then
    echo $2 > $sourcesDir/$1.list
  fi
}

apt-install() {
  dpkg-query -s $1 > /dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    apt-get -y install $1
  fi
}

apt-purge() {
  dpkg-query -s $1 > /dev/null 2>&1
  if [ "$?" -eq 0 ]
  then
    aptitude -y purge $1
  fi
}

aptitude-install() {
  dpkg-query -s $1 > /dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    aptitude -y install $1
  fi
}

dpkg-install() {
  dpkg-query -s $1 > /dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    wget $2
    debfile=`basename $2`
    dpkg -i install $debfile
    rm -f $debfile
  fi
}

gem-install() {
  gem list | grep $1 > /dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    gem install $1
  fi
}

PURGE_DEBS=(vim-tiny)
PPAS=(git-core/ppa sevenmachines/flash)

SYSTEM_DEBS=(ppa-purge git-svn openssh-server synergy virtualbox-4.1 screen connect-proxy)
RVM_DEBS=(build-essential bison openssl libreadline6 libreadline6-dev curl
git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev
sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev)
VIM_DEBS=(vim-gtk exuberant-ctags ack-grep)
WEB_DEBS=(firefox chromium-browser flashplugin64-installer)
MISC_DEBS=(calibre pdfedit gtk-recordMyDesktop nautilus-dropbox acroread vlc)

GEMS=(bundler vagrant veewee chef rvm yard)

setup-debian-packages() {

  export DEBIAN_FRONTEND="noninteractive"

  if ! (ping -c 1 dropbox.com | grep opendns > /dev/null 2>&1 )
  then
    DROPBOX=0
  else
    DROPBOX=1
  fi

  sed -i -e 's|# deb http://archive.canonical.com/ubuntu natty partner|deb http://archive.canonical.com/ubuntu natty partner|' /etc/apt/sources.list
  for ppa in ${PPAS[*]}
  do
    list=`echo $ppa | tr '/' '-'`-$DISTRIB_CODENAME
    if [ ! -f "/etc/apt/sources.list.d/$list.list" ]
    then
      apt-add-repository ppa:$ppa
    fi
  done
  apt-add-list virtualbox 'deb http://download.virtualbox.org/virtualbox/debian natty contrib'
  wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add - > /dev/null 2>&1
  if [ ${DROPBOX} -eq 0 ]
  then
    apt-add-list dropbox 'deb http://linux.dropbox.com/ubuntu natty main'
    apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
  fi

#  dpkg-install teamviewer6 http://www.teamviewer.com/download/teamviewer_linux_x64.deb

  apt-install aptitude
  apt-purge ${PURGE_DEBS[*]}
  aptitude update
  aptitude -y upgrade

  INSTALL_ARRAYS=`declare -a | grep DEBS | grep -v PURGE_DEBS | awk -F'=' '{print $1}' | awk -F'-a ' '{print $2}'`
  for array in ${INSTALL_ARRAYS[*]}
  do
    eval aptitude-install \"\${$array[*]}\"
  done
  ln -sf /usr/bin/ack-grep /usr/bin/ack
  aptitude autoclean
}


setup-ruby() {
  if [ ! -d "/usr/local/rvm" ]
  then
    bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
  fi
  . /etc/profile

  rvm list | grep ree > /dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    echo "gem: --no-rdoc --no-ri" > /etc/gemrc
    rvm install ree
    rvm --create --default ree@system
  fi

  for gem in ${GEMS[*]}
  do
    gem-install $gem
  done
}

setup-debian-packages
setup-ruby

for i in `find "$HOME/dotfiles/bash_completion.d" -name '*.bash'`
do
  grep "$i" "$HOME/.bashrc" > /dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    echo ". $i" >> $HOME/.bashrc
  fi
done

for i in `find "$HOME/dotfiles" -maxdepth 1 -not -name '.git' -not -name '.gitmodules' -not -name '.gitignore' -name '.*'`
do
  dotfile="$HOME/`basename $i`"
  if [ ! -h "$dotfile" ]
  then
    ln -sf "$i" "$dotfile"
  fi
done
