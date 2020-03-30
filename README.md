Comp 601 Wireshark Brute Force RLO

The motivation for this project was to simplify the build process for setup for blue team members.  Setup for DVWA (https://github.com/ethicalhack3r/DVWA) and Kali Linux (https://www.kali.org/) in virtual machines is well documented. Still, it is a significant task for newcomers who are trying to concentrate on blue team concepts.  

There are three parts to this exercise.  The first part creates the vulnerable web server host and kali Linux qemu machines.  The second setup part involves copying the files from the upload_files folder to the clients and setting up aspects of the virtual machines.  The scripting is based on properties of consistency that one can use when assuming that you have specific new machines of a particular version.  The third part is simulating the attack so that it can be seen in Wireshark.  The upload file "attack.sh" uses some curl commands and hydra to simulate a brute force attack against the DVWA server.  The "start_wireshark" script assumes the local user can run Wireshark.  The script starts Wireshark with friendly settings to eliminate the normal network activities that are present on the host system.  

Youtube video playlist is available at:
https://www.youtube.com/watch?v=_RDecU6QCqA&list=PLL1BUmDIkm6Tle26KtbG20Wj2Sme0Hkix
