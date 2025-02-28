# IB_Switch_Walk
## Bash tool to walk all IB switches and check for down ports


The script check_all_ports.sh is a tool to walk all IB switches in an HPC/AI cluster using the smpwalk utility and check for down ports. It will then respond with 
* Switch Name and Port [xx] that shows down
* Switch location, RU#, Serial Number, IP Address
* What switch or node "should" be on the other end of the port and port [yy] or mlx5_#
* Switch location, RU#, Serial Number, IP Address

  
The tool uses 3 primary files to do this. 

- check_all_ports.sh
- cleaned_topology.out
- ndr_switches.out
- switches.map


A cleaned up Topology file created with "ibnetdiscover > ib_topology" then modified using the commands in cleanup_topology.info

Beware ibnetdiscover. If you have a port down or a node offline it'll just skip that port on the switch. IE it won't have that port in the list and you'll need to add it manually or the "To" switch will be one off. Not sure how to get around this yet. So, if port 35 of switch leaf10 is down it'll go
[33],[34],[36],[37]

A file called ndr_switches.out that is a mapping of all switch information. This is used to output the switch info for down ports. The script does a "switch name" lookup against this file and pulls the info.
Switch_Name, location, RU#, Serial_Number, IP_Addr (The file here has been cleaned up to be generic)

You will also need to create an array in switches.map that has the smpwalk map to each switch. In this example I have 64 leaf switches I walk through. So the array is 0-64 (I ignore [0]). 


Rich
