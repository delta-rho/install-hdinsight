#!/usr/bin/env bash

# https://azure.microsoft.com/en-us/documentation/articles/hdinsight-hadoop-script-actions-linux/
# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

# Install the latest version of R.
OS_VERSION=$(lsb_release -sr)
if [[ $OS_VERSION == 14* ]]; then
  echo "OS verion is $OS_VERSION. Using R Trusty Tahr release."
  echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" | tee -a /etc/apt/sources.list
else
  echo "OS verion is $OS_VERSION. Using R Precise Pangolin release."
  echo "deb http://cran.rstudio.com/bin/linux/ubuntu precise/" | tee -a /etc/apt/sources.list
fi

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
add-apt-repository -y ppa:marutter/rdev
apt-get -y --force-yes update
apt-get -y --force-yes install r-base r-base-dev

if [ ! -e /usr/bin/R -o ! -e /usr/local/lib/R/site-library ]; then
  echo "Either /usr/bin/R or /usr/local/lib/R/site-library does not exist. Retry installing R"
  sleep 15
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
  add-apt-repository -y ppa:marutter/rdev
  apt-get -y --force-yes update
  apt-get -y --force-yes install r-base r-base-dev
fi

if [ ! -e /usr/bin/R -o ! -e /usr/local/lib/R/site-library ]; then
  echo "Either /usr/bin/R or /usr/local/lib/R/site-library does not exist after retry. Exiting..."
  exit 1
fi

# Download packages.
download_file https://hdiconfigactions.blob.core.windows.net/linuxrconfigactionv01/r-site-library.tgz /tmp/r-site-library.tgz
untar_file /tmp/r-site-library.tgz /usr/local/lib/R/site-library/

# Remove temporary files.
rm -f /tmp/r-site-library.tgz

sudo apt-get -y --force-yes install libcurl4-openssl-dev libapparmor1

## CONFIG
function eVal {
  echo $1 | tee -a /home/tessera/.Renviron
  echo $1 | sudo tee -a /usr/lib/R/etc/Renviron
  echo export $1 | tee -a /home/tessera/.bashrc
}

HDP_VERSION=`ls /usr/hdp | head -1`
hdpcl=`hadoop classpath | tr -d '*'`

eVal 'HDP_VERSION='$HDP_VERSION
eVal 'HADOOP=/usr/hdp/'$HDP_VERSION'/hadoop'
eVal 'HADOOP_HOME=/usr/hdp/'$HDP_VERSION'/hadoop'
eVal 'HADOOP_BIN=/usr/hdp/'$HDP_VERSION'/hadoop/bin'
eVal 'HADOOP_CONF_DIR=/usr/hdp/'$HDP_VERSION'/hadoop/conf'
eVal 'HADOOP_OPTS=-Djava.awt.headless=true'
eVal 'HADOOP_LIBS='$hdpcl
eVal 'LD_LIBRARY_PATH=/usr/local/lib:/usr/hdp/'$HDP_VERSION'/lib/native:$LD_LIBRARY_PATH'

echo 'RSTUDIO_DISABLE_SECURE_DOWNLOAD_WARNING=1' | sudo tee -a /usr/lib/R/etc/Renviron

echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server" | sudo tee -a /etc/environment
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server" | sudo tee -a /etc/R/Renviron
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server

# echo 'LD_LIBRARY_PATH=/usr/local/lib:/home/hadoop/lib/native:/usr/lib64:/usr/local/cuda/lib64:/usr/local/cuda/lib:$LD_LIBRARY_PATH' | sudo tee -a /etc/R/Renviron
# echo '/usr/java/jdk1.7.0_65/jre/lib/amd64/server/' | sudo tee -a  /etc/ld.so.conf.d/jre.conf
# echo '/usr/java/jdk1.7.0_65/jre/lib/amd64/' | sudo tee -a  /etc/ld.so.conf.d/jre.conf
# echo '/home/hadoop/.versions/2.4.0/lib/native/' | sudo tee -a  /etc/ld.so.conf.d/hadoop.conf
# sudo ldconfig

# set repositories
echo 'options(repos=c(tessera="http://packages.tessera.io", CRAN="http://cran.rstudio.com"))' | sudo tee -a /usr/lib/R/library/base/R/Rprofile

sudo su - -c "R -e \"install.packages(c('lubridate', 'housingData', 'devtools', 'datadr', 'trelliscope', 'rbokeh'))\""

#protobuf 2.5.0 comes with hadoop but need the .so files
export PROTO_BUF_VERSION=2.5.0
wget https://protobuf.googlecode.com/files/protobuf-$PROTO_BUF_VERSION.tar.bz2
tar jxvf protobuf-$PROTO_BUF_VERSION.tar.bz2
cd protobuf-$PROTO_BUF_VERSION
./configure && make -j4
sudo make install
cd ..

# rhipe
ver=$(wget -qO- http://ml.stat.purdue.edu/rhipebin/current.ver)
export RHIPE_VERSION=${ver}_hadoop-2

wget http://ml.stat.purdue.edu/rhipebin/Rhipe_$RHIPE_VERSION.tar.gz

sudo R CMD javareconf

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
sudo chmod 777 /usr/local/lib/R/site-library
sudo chmod -R 777 /usr/share/
sudo R CMD INSTALL Rhipe_$RHIPE_VERSION.tar.gz
rm -rf protobuf-2.5.0
rm protobuf-2.5.0.tar.bz2
rm Rhipe_0.75.2_hadoop-2.tar.gz

## RStudio Server, etc.

sudo su - -c "R -e \"install.packages('shiny')\""
sudo su - -c "R -e \"install.packages('rmarkdown')\""

## rstudio server
wget -q https://s3.amazonaws.com/rstudio-server/current.ver -O currentVersion.txt
ver=$(cat currentVersion.txt)
wget http://download2.rstudio.org/rstudio-server-${ver}-amd64.deb
sudo dpkg -i rstudio-server-${ver}-amd64.deb
rm rstudio-server-*-amd64.deb currentVersion.txt
echo "www-port=8002" | tee -a /etc/rstudio/rserver.conf
# echo "rsession-ld-library-path=/usr/local/lib" | tee -a /etc/rstudio/rserver.conf
rstudio-server restart

## shiny server
ver=$(wget -qO- https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION)
wget https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-${ver}-amd64.deb -O shiny-server.deb
sudo dpkg -i shiny-server.deb
rm shiny-server.deb
sudo mkdir /srv/shiny-server/examples
sudo cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/examples
sudo chown -R shiny:shiny /srv/shiny-server/examples

hadoop fs -mkdir -p /user/tessera/bin

sudo chmod -R 755 /usr/local/lib/R/site-library

sudo su - tessera -c "R -e \"library(Rhipe); rhinit(); hdfs.setwd('/user/tessera/bin'); bashRhipeArchive('R.Pkg')\""

# library(Rhipe)
# rhinit()
# rhoptions(zips = '/user/tessera/bin/R.Pkg.tar.gz')
# rhoptions(runner = 'sh ./R.Pkg/library/Rhipe/bin/RhipeMapReduce.sh')
# rhoptions(mropts = c(rhoptions()$mropts, list(hdp.version = Sys.getenv("HDP_VERSION"))))

# echo "exec /usr/bin/R CMD /usr/local/lib/R/site-library/Rhipe/bin/RhipeMapReduce --slave --silent --vanilla" | sudo tee -a /home/hadoop/rhRunner.sh

# sudo chmod 755 -R /home/tessera
