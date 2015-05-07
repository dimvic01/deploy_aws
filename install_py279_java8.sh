#!/bin/bash

sudo apt-get update

sudo apt-get upgrade

wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz

tar xfz Python-2.7.9.tgz

cd Python-2.7.9/

sudo apt-get install -y gcc-multilib g++-multilib libffi-dev libffi6 libffi6-dbg python-crypto \
python-mox3 python-pil python-ply libssl-dev zlib1g-dev libbz2-dev libexpat1-dev libbluetooth-dev \
libgdbm-dev dpkg-dev quilt autotools-dev libreadline-dev libtinfo-dev libncursesw5-dev tk-dev \
blt-dev libssl-dev zlib1g-dev libbz2-dev libexpat1-dev libbluetooth-dev libsqlite3-dev libgpm2 \
mime-support netbase net-tools bzip2

./configure --prefix /usr/local/lib/python2.7.9

make && sudo make install

/usr/local/lib/python2.7.9/bin/python -V

sudo add-apt-repository -y ppa:webupd8team/java

sudo apt-get update

echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections

sudo apt-get install -y oracle-java8-installer

java -version

exit 0
