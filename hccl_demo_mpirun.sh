#!/bin/bash
#
# Copyright (C) 2024 Supermicro.
# All Rights Reserved.
#
# Unauthorized copying of this file, via any medium is strictly prohibited.
# Proprietary and confidential.
#
trap "set +x; sleep 5; set -x" DEBUG

function check_directory(){
    if [ -d $1 ]
    then
     echo "$1: dir present"
    else
     echo "$1: dir not present, create it"
     mkdir -p $1
    fi
}

CONFIG_DATABASE_TEST_ITEM_HCCL_TEST=1
test_type=$1
test_size=$2
test_loop=$3

# Define the input file
infile=$4
host_list=""
logging_dir=$HOME/testDepot/HCCL_DEMO/logs
report_dir=$HOME/testDepot/HCCL_DEMO/reports
workspace_dir=$HOME/testDepot/HCCL_DEMO/

NEW_PKGS_DIR=/opt/habanalabs/openmpi-4.1.5
echo $logging_dir

hl-smi -q >.temp_hl_readings
gpu_number=`cat .temp_hl_readings |grep AIP |grep -c "^\["`
echo $gpu_number
rm .temp_hl_readings

# Read the input file line by line
while read -r LINE
do
        #printf '%s\n' "$LINE"
        host_list="${LINE}:${gpu_number},${host_list}"
        lastvalue=$host_list
done < $infile
hostlists=$( echo $lastvalue | rev | cut -c2- | rev)


if [[ $gpu_number -gt 0 ]];then
  if [[ $CONFIG_DATABASE_TEST_ITEM_HCCL_TEST -ne 0 ]];then
    data_s_stamp=`date +"%s"`
		dmesg -T |egrep -iv "(Command|autorunme)" > $logging_dir/.dmesg_before_nccl_dump
		#cp -f $logging_dir/.dmesg_before_nccl_dump ${uppath}/yam_debug-information/nccl_debug_info_with_dmesg_before_hccl_test_$data_s_stamp.log > /dev/null 2>&1

		#####generate_status_file "HCCL" "Start"

    check_directory $logging_dir
    check_directory $report_dir
    check_directory $workspace_dir

		cd $workspace_dir
		hccl_test="hccl_demo"

		if [[ ! -d "$hccl_test" ]];then
		  ######generate_log_file "HCCL Test program found - skip."
			#####generate_status_file "No HCCL Test program found - fail" "fail"
			echo "No HCCL Test Program Found, Install the Program now"
			git clone https://github.com/HabanaAI/hccl_demo.git
		else
		  cd $hccl_test
		fi

		# manage_network_ifs.sh requires ethtool
		# Bring up Network Interface
    sudo apt-get install ethtool
    sudo /opt/habanalabs/qual/gaudi2/bin/manage_network_ifs.sh --up
    sleep 5

    if [[ ! -d "/opt/habanalabs/openmpi-4.1.5" ]]; then
	    # install openmpi-4.1.5 under habanalabs directory
	    sudo wget -nv https://vault.habana.ai/artifactory/gaudi-installer/1.13.0/habanalabs-installer.sh
      sudo chmod +x habanalabs-installer.sh
      sleep 5
      ./habanalabs-installer.sh install -t dependencies
      echo "Waiting for installation dependencies to complete"
    else
	    echo "There is openmpi-4.1.5 already installed"
	    MPI_ROOT=/opt/habanalabs/openmpi-4.1.5
      LD_LIBRARY_PATH=/opt/habanalabs/openmpi-4.1.5/lib:
      OPAL_PREFIX=/opt/habanalabs/openmpi-4.1.5
      PATH=/opt/habanalabs/openmpi-4.1.5/bin:$PATH
      export MPI_ROOT
      export LD_LIBRARY_PATH
      export OPAL_PREFIX
    fi
    ######generate_status_file "HCCL Test" "Waiting"
    echo "Waiting for another node to be ready.........."
    #####generate_log_file "Waiting for another node to be ready"

    cd $workspace_dir
    cd $hccl_test
    make clean
    MPI=1 make
    runloop=1

    for ((r=1;r<=$runloop;r++)); do
	    #####generate_status_file "HCCL AllReduce-$r" "running"
	    #
      #python3 run_hccl_demo.py --test $test_type --loop 2000 --size ${test_size}m -mpi --host $head_node:$gpu_number,$pair_node:$gpu_number 2>&1 |tee $logging_dir/.hccl_s
      python3 run_hccl_demo.py --test $test_type --loop $test_loop --size ${test_size}m -mpi --host $hostlists 2>&1 |tee $logging_dir/.hccl_s
	    echo "#" > $logging_dir/.hccl_s_${test_type}_dump
	    cat $logging_dir/.hccl_s |sed "s/ Demo//g;s/\/tmp//g;s/ demo//g;s/^#/+/g;s/#$/+/g;s/#/-/g" >> $logging_dir/.hccl_s_${test_type}_dump
	    if [[ `egrep -ic "BENCHMARK" $logging_dir/.hccl_s_${test_type}_dump` -ne 0 ]]; then
		    sleep 5
		    #_clear_cache_buffer
		    cp -f $logging_dir/.hccl_s_${test_type}_dump /var/tmp/hccl_local-${test_type}-running-loop.$r.log
		  
		    cat $logging_dir/.hccl_s_${test_type}_dump >> $logging_dir/habana_gpu-hccl-${test_type}-full.log
		    echo "" >> $logging_dir/habana_gpu-hccl-${test_type}-full.log
		    echo "" >> $logging_dir/habana_gpu-hccl-${test_type}-full.log
		    echo "" >> $logging_dir/habana_gpu-hccl-${test_type}-full.log
	   fi
    done
		gpu_number=`lspci |grep -ic Habana`
		gpu_dtype=`cat $logging_dir/habana_gpu-hccl-${test_type}-full.log |grep BENCHMARK |grep dtype |awk -F\dtype '{print$2}' |awk '{print$1}' |sed "s/,//g;s/=//g" |head -n1`
		gpu_count=`cat $logging_dir/habana_gpu-hccl-${test_type}-full.log |grep BENCHMARK |grep dtype |awk -F\count '{print$2}' |awk '{print$1}' |sed "s/,//g;s/=//g" |head -n1`
		gpu_itera=`cat $logging_dir/habana_gpu-hccl-${test_type}-full.log |grep BENCHMARK |grep dtype |awk -F\iterations '{print$2}' |awk '{print$1}' |sed "s/,//g;s/=//g;s/)$//g" |head -n1`
		gpu_nw_bw=`cat $logging_dir/habana_gpu-hccl-${test_type}-full.log |grep -i "NW Bandwidth" |awk -F\: '{print$2}' |sed 's/^[[:space:]]*//' |sort -uV |tail -1`
		gpu_algo_bw=`cat $logging_dir/habana_gpu-hccl-${test_type}-full.log |grep -i "Algo Bandwidth" |awk -F\: '{print$2}' |sed 's/^[[:space:]]*//' |sort -uV |tail -1`
		echo "${test_type};$gpu_number;$gpu_dtype;$gpu_count;$gpu_itera;$gpu_nw_bw;$gpu_algo_bw" >>/var/tmp/.gpu_hcll_test
		#sleep 30
		cat $logging_dir/.hccl_s_${test_type}_dump |grep -i BENCHMARK > $report_dir/.hccl-${test_type}-report
		#####generate_log_file "Single node HCCL AllReduce logs..."
		while read line
		do
		  getline=$(echo $line |sed "s/;/ /g")
			if [[ "$getline" != "" ]];then
			  #####generate_log_file "$getline"
			  echo "getline: $getline"
			fi
		done < $report_dir/.hccl-${test_type}-report
		if [[ `egrep -ic "BENCHMARK" $logging_dir/.hccl_s_${test_type}_dump` -eq 0 ]];then
		  ######generate_log_file "HCCL AllReduce Test on local node fail, please refer to yam_debug/hccl_local-all_reduce"
			######generate_status_file "HCCL AllReduce Test on local node fail, please refer to yam_debug/hccl_local-all_reduce" "fail"
		  echo "HCCL ${test_type} Test on multi nodes fails, please refer to $logging_dir/.hccl_s_${test_type}_dump"
		else
		  echo "HCCL ${test_type} Test on multi nodes is successful, please refer to $report_dir/.hccl-${test_type}-report"
		  cat $report_dir/.hccl-${test_type}-report
		fi
  else
			######generate_log_file "Skip HCCL test according to the custom settings."
		  echo "Skip HCCL Test According to the Custom Settings"
fi
fi


