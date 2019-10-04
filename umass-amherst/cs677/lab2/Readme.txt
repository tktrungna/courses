Each peer has one configuration file that assigns item and connection with other peers. These configuration files is under conf/ folder.  If we need to change the IP, port, name or network connection, we need the change the code in file create_configure.py

If we don’t want to change the network, just use the submitted configuration file.
To start a peer:
python test_client.py


sh run_multi_peers.sh (run_multi_peers_ec2.sh or run_multi_peers_edlab.sh for corresponding environment)
sh test_client.py
input 0
(change to different terminal: sh test_client.py
input 9
>>> vote
>>> buy coin
>>> buy 1000 coin
(change to client 9) >>> resign
(change back to client 0) >>> buy laptop
>>> buy laptop
>>> close
