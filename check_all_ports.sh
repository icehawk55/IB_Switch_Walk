#!/bin/bash

#==================================================
# Written by Rich Hickey
# rhickey@applieddigital.com
# This script will walk through all cluster leaf
# switches checking for down ports
#==================================================

#-----------------------------------------------------------------
# This is an array of all leaf switches based on IB port locations
# Because of our Rail optimization to get to all switches I had to
# use an unusual pathing. UFM to Leaf to Spine then back to all leafs. 
#
# /usr/sbin/smpquery -C mlx5_0 -D ND 0
# ufm01 HCA-1
# /usr/sbin/smpquery -C mlx5_0 -D ND 0,1
# cluster-p2-ndr-spine32
# /usr/sbin/smpquery -C mlx5_0 -D ND 0,1,1
# cluster-p1-ndr-leaf01
# /usr/sbin/smpquery -C mlx5_0 -D ND 0,1,1,33
# cluster-p1-ndr-spine01
# /usr/sbin/smpquery -C mlx5_0 -D ND 0,1,1,33,1
# cluster-p1-ndr-leaf01
#-----------------------------------------------------------------
leaf[0]="0,1,1,33"
leaf[1]="0,1,1,33,1"
leaf[2]="0,1,1,33,2"
leaf[3]="0,1,1,33,3"
leaf[4]="0,1,1,33,4"
leaf[5]="0,1,1,33,5"
leaf[6]="0,1,1,33,6"
leaf[7]="0,1,1,33,7"
leaf[8]="0,1,1,33,8"
leaf[9]="0,1,1,33,9"
leaf[10]="0,1,1,33,10"
leaf[11]="0,1,1,33,11"
leaf[12]="0,1,1,33,12"
leaf[13]="0,1,1,33,13"
leaf[14]="0,1,1,33,14"
leaf[15]="0,1,1,33,15"
leaf[16]="0,1,1,33,16"
leaf[17]="0,1,1,33,17"
leaf[18]="0,1,1,33,18"
leaf[19]="0,1,1,33,19"
leaf[20]="0,1,1,33,20"
leaf[21]="0,1,1,33,21"
leaf[22]="0,1,1,33,22"
leaf[23]="0,1,1,33,23"
leaf[24]="0,1,1,33,24"
leaf[25]="0,1,1,33,25"
leaf[26]="0,1,1,33,26"
leaf[27]="0,1,1,33,27"
leaf[28]="0,1,1,33,28"
leaf[29]="0,1,1,33,29"
leaf[30]="0,1,1,33,30"
leaf[31]="0,1,1,33,31"
leaf[32]="0,1,1,33,32"
leaf[33]="0,1,1,33,33"
leaf[34]="0,1,1,33,34"
leaf[35]="0,1,1,33,35"
leaf[36]="0,1,1,33,36"
leaf[37]="0,1,1,33,37"
leaf[38]="0,1,1,33,38"
leaf[39]="0,1,1,33,39"
leaf[40]="0,1,1,33,40"
leaf[41]="0,1,1,33,41"
leaf[42]="0,1,1,33,42"
leaf[43]="0,1,1,33,43"
leaf[44]="0,1,1,33,44"
leaf[45]="0,1,1,33,45"
leaf[46]="0,1,1,33,46"
leaf[47]="0,1,1,33,47"
leaf[48]="0,1,1,33,48"
leaf[49]="0,1,1,33,49"
leaf[50]="0,1,1,33,50"
leaf[51]="0,1,1,33,51"
leaf[52]="0,1,1,33,52"
leaf[53]="0,1,1,33,53"
leaf[54]="0,1,1,33,54"
leaf[55]="0,1,1,33,55"
leaf[56]="0,1,1,33,56"
leaf[57]="0,1,1,33,57"
leaf[58]="0,1,1,33,58"
leaf[59]="0,1,1,33,59"
leaf[60]="0,1,1,33,60"
leaf[61]="0,1,1,33,61"
leaf[62]="0,1,1,33,62"
leaf[63]="0,1,1,33,63"
leaf[64]="0,1,1,33,64"


#-----------------------------------------------------------------
# Walk through the switch array. 
#-----------------------------------------------------------------
for i in $(seq 1 64)
do
	#-----------------------------------------------------------------
	# Walk through the switch ports 1-64 on spine01
	# Ports 1-32 are node ports
	# Ports 33-64 are switch to switch ports
	#-----------------------------------------------------------------
	for port in $(seq 1 64)
	do
		/usr/sbin/smpquery -C mlx5_0 -D ND ${leaf[$i]},$port 1&> /dev/null

		#-----------------------------------------------------------------
		# If the smpquery command returns fail then print the following
		#-----------------------------------------------------------------
		if [ $? -ne 0 ]
		then
			#--------------------------------------------------------------------
			# Pull the local switch information
			# uses ndr switch information file to get location information
			#--------------------------------------------------------------------
			echo "----------------------------------------------"
			#echo "/usr/sbin/smpquery -C mlx5_0 -D ND ${leaf[$i]},$port" #Command to manually check port
			LOCAL_SWITCH=$(/usr/sbin/smpquery -C mlx5_0 -D ND ${leaf[$i]} |awk -F \; '{print $2}' |awk -F\: '{print $1}')
			LOCAL_INFO=$(grep ^${LOCAL_SWITCH} ndr_switches.out|awk '{print $2,$3,$4,$5}')
			echo "${LOCAL_SWITCH} Port [${port}] "
			echo ${LOCAL_INFO}
			echo "To "

			#--------------------------------------------------------------------
			# Pull the remote switch information. Uses a cleaned IB topology file
			# and an ndr switch information file to get location information
			#--------------------------------------------------------------------
			REMOTE_SWITCH=$(grep -A${port} ^${LOCAL_SWITCH} cleaned_topology.out |tail -1 |awk '{print $2}')
			if [[ "$REMOTE_SWITCH" == "cluster"* ]]
            		then
                		REMOTE_PORT=$(grep -A64 ^${REMOTE_SWITCH} cleaned_topology.out |grep ${LOCAL_SWITCH} |awk '{print $1}')
                		REMOTE_INFO=$(grep ^${REMOTE_SWITCH} ndr_switches.out|awk '{print $2,$3,$4,$5}')
                		echo "${REMOTE_SWITCH} Port ${REMOTE_PORT}"
                		echo ${REMOTE_INFO}
                		echo
            		else
                		REMOTE_SWITCH=$(grep -A${port} ^${LOCAL_SWITCH} cleaned_topology.out |tail -1 |awk -F\" '{print $2}')
                                echo "${REMOTE_SWITCH}"
                                echo
            		fi
		fi
	done
done > /root/scripts/output.txt


#-----------------------------------------------------------------
# email the results
#-----------------------------------------------------------------
/bin/mail -s "`date +%m/%d/%Y` Cluster Ports" BarneyRubble@bedrock.com < /root/scripts/output.txt


