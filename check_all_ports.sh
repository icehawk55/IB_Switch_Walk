#!/bin/bash

#==================================================
# Written by Rich Hickey
# @applieddigital.com
# This script will walk through all leaf
# switches checking for down ports
#==================================================


#==================================================
# Set a variable with where the script is running from
# and check for all files needed
#==================================================
DIR=$(dirname -- "$0")

if [ ! -f "${DIR}/switches.map" ]; then
	echo "${DIR}/switches.map file is missing"
	exit 1
fi

if [ ! -f "${DIR}/ndr_switches.out" ]; then
        echo "${DIR}/ndr_switches.out file is missing"
        exit 1
fi

if [ ! -f "${DIR}/cleaned_topology.out" ]; then
        echo "${DIR}/cleaned_topology.out file is missing"
        exit 1
fi

#==================================================
# Source the switch mapping array
#==================================================
source ${DIR}/switches.map


#-----------------------------------------------------------------
# Walk through the switch array sourced via switches.map 
# Array [0] is ignored. It messes up the counts
#-----------------------------------------------------------------
for MAP in $(seq 1 $(( ${#leaf[@]} -1 )))
do
	#-----------------------------------------------------------------
	# This line is for diagnostics. It prints the array #, 
	# The switch map and then the switch name.
	#-----------------------------------------------------------------
	# echo "${MAP} is ${leaf[$MAP]} $(/usr/sbin/smpquery -C mlx5_0 -D ND ${leaf[$MAP]}|awk -F \; '{print $2}' |awk -F\: '{print $1}')"


	#-----------------------------------------------------------------
	# Walk through the switch ports 
	# Ports 1-32 are node ports in rail optimized topology
	# Ports 33-64 are switch to switch ports in rail optimized topology
	#-----------------------------------------------------------------
	for port in $(seq 33 64)
	do
		/usr/sbin/smpquery -C mlx5_0 -D ND ${leaf[$MAP]},$port 1&> /dev/null

		#-----------------------------------------------------------------
		# If the smpquery command returns fail, ie a down port 
       		# then print the following information
		#-----------------------------------------------------------------
		if [ $? -ne 0 ]
		then
			#--------------------------------------------------------------------
			# Pull the local switch information
			# uses ndr switch information file to get location information
			#--------------------------------------------------------------------
			echo "----------------------------------------------"
			#echo "/usr/sbin/smpquery -C mlx5_0 -D ND ${leaf[$MAP]},$port" #Command to manually check port
			LOCAL_SWITCH=$(/usr/sbin/smpquery -C mlx5_0 -D ND ${leaf[$MAP]} |awk -F \; '{print $2}' |awk -F\: '{print $1}')
			LOCAL_INFO=$(grep ^${LOCAL_SWITCH} ${DIR}/ndr_switches.out|awk '{print $2,$3,$4,$5}')
			echo "${LOCAL_SWITCH} Port [${port}] "
			echo ${LOCAL_INFO}
			echo "To "

			#--------------------------------------------------------------------
			# Pull the remote switch information. Uses a cleaned IB topology file
			# and an ndr switch information file to get location information
			#--------------------------------------------------------------------
			REMOTE_SWITCH=$(grep -A${port} ^${LOCAL_SWITCH} ${DIR}/cleaned_topology.out |tail -1 |awk '{print $2}')
			if [[ "$REMOTE_SWITCH" == "cluster"* ]] #This looks for switch naming vs node naming
            		then
				REMOTE_PORT=$(grep -A64 ^${REMOTE_SWITCH} ${DIR}/cleaned_topology.out |grep ${LOCAL_SWITCH} |awk '{print $1}')
				REMOTE_INFO=$(grep ^${REMOTE_SWITCH} ${DIR}/ndr_switches.out|awk '{print $2,$3,$4,$5}')
                		echo "${REMOTE_SWITCH} Port ${REMOTE_PORT}"
                		echo ${REMOTE_INFO}
                		echo
            		else
				REMOTE_SWITCH=$(grep -A${port} ^${LOCAL_SWITCH} ${DIR}/cleaned_topology.out |tail -1 |awk -F\" '{print $2}')
                                echo "${REMOTE_SWITCH}"
                                echo
            		fi
		fi
	done
done > ${DIR}/output.txt
#done


#-----------------------------------------------------------------
# email the results
#-----------------------------------------------------------------
/bin/mail -s "`date +%m/%d/%Y` Cluster Down Ports" BarneyRubble@Bedrock.com < ${DIR}/output.txt

