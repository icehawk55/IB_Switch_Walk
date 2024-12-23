# IB_Switch_Walk
Bash tool to walk all IB switches and check for down ports


The script check_all_ports.sh is a tool to walk all IB switches in an HPC/AI cluster using the smpwalk utility and check for down ports. The tool uses 3 primary files to do this. 
check_all_ports.sh
cleaned_topology.out
ndr_switches.out

A cleaned up Topology file created with "ibnetdiscover > ib_topology" then modified using the commands in cleanup_topology.info

A file called ndr_switches.out that is a mapping of all switch information. This is used to output the switch info for down ports.
Switch_Name, location, RU#, Serial_Number, IP_Addr

You will also need to create an array in check_all_ports.sh that has the smpwalk map to each switch. In this script I have 64 leaf switches I walk through. So the array is 0-64 (I ignore [0]). 


