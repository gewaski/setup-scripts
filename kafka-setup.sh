# !/bin/bash
# Copyright (c) 2014
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# zhangwei13 <alucard.hust@gmail.com>
#

. ./buildconf;
. ./func.sh;


function printHelp()
{
    echo "$0 -c -r -d -k -F -f -h";
}

while getopts "crdkhFf" OPTION
do
  case $OPTION
  in
    c)needConfig=1;;
    r)needRestart=1;;
    d)needDistribute=1;;
    F)needFormat=1;;
    f)needFreeup=1;;
    k)needKill=1;;
    h)printHelp;
	exit 1;;
    /?)printHelp;
    exit 1;;
  esac
done

if [ x"$needDistribute" = x"1" ];then
	echo -e "\033[;33;4m distribute bin \033[0m"
	for ((i=0; i<${#allKafkaServers[@]}; i+=2));do
		
		remote_scp ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "$KAFKAJAR" $INSTALLDIR
		remote_scp ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "local_exec.sh remote_local_kill.sh kafka-server-start-512M.sh" $INSTALLDIR

		# limit java heap to 512M
	    remote_exec ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "
			mkdir -p $INSTALLDIR;
			pushd $INSTALLDIR;
			mkdir -p $KAFKAEXECDIR;
			tar vxf $KAFKAJAR -C $INSTALLDIR > /dev/null;
			cp kafka-server-start-512M.sh $KAFKAEXECDIR/bin/kafka-server-start.sh -f;
		"
	done
fi

if [ x"$needFormat" = x"1" ];then
	echo -e "\033[;33;4m remove all  \033[0m"
	for ((i=0; i<${#allKafkaServers[@]}; i+=2));do
		
		# shutdown possible kafka firstly
	    	remote_exec ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "
			pushd $INSTALLDIR;
			sh remote_local_kill.sh "kafka.Kafka"
			rm $KAFKADATALOGDIR -rf;
		"
	done
fi

if [ x"$needConfig" = x"1" ];then
	echo -e "\033[;33;4m config kafka \033[0m"
	for ((i=0; i<${#allKafkaServers[@]}; i+=2));do

		sh genkafkaconf $((i/2))

		remote_exec ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "
			mkdir $KAFKADATALOGDIR -p;
		"
		remote_scp ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} \
		$TMPCONFIGDIR/server.properties.$((i/2)) \
		$KAFKAEXECDIR/config/server.properties;
	done
fi

if [ x"$needFreeup" = x"1" ];then
	echo -e "\033[;33;4m free up system \033[0m"
	for ((i=0; i<${#allKafkaServers[@]}; i+=2));do
	    remote_exec ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "
			free -m;
			sync;
			sudo echo 3 > /proc/sys/vm/drop_caches;
			free -m;
		"
	done
fi

if [ x"$needKill" = x"1" ];then
	echo -e "\033[;33;4m kill kafka \033[0m"
	for ((i=0; i<${#allKafkaServers[@]}; i+=2));do
	    remote_exec ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "
			pushd $INSTALLDIR;
			sh remote_local_kill.sh "kafka.Kafka"
			sh $KAFKAEXECDIR/bin/kafka-server-stop.sh;
		"
	done
fi

if [ x"$needRestart" = x"1" ];then
	echo -e "\033[;33;4m restart kafka \033[0m"
	for ((i=0; i<${#allKafkaServers[@]}; i+=2));do
	    remote_exec ${allKafkaServers[$((i))]} ${allKafkaServers[$((i+1))]} "
			pushd $INSTALLDIR;
			sh remote_local_kill.sh "kafka.Kafka"
			sh $KAFKAEXECDIR/bin/kafka-server-stop.sh;
			sh $KAFKAEXECDIR/bin/kafka-server-start.sh -daemon $KAFKAEXECDIR/config/server.properties;
		"
	done
fi
