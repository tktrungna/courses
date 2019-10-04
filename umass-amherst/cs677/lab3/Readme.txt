Each peer has one configuration file that assigns item and connection with other peers. These configuration files is under conf/ folder.  If we need to change the IP, port, name or network connection, we need the change the code in file create_configure.py

If we don’t want to change the network, just use the submitted configuration file.
To start a peer:
python test_client.py


sh run_multi_peers.sh (run_multi_peers_ec2.sh or run_multi_peers_edlab.sh for corresponding environment)
sh test_client.py
input 0
(change to different terminal): sh trader.py
input 0
(change to different terminal): sh trader.py
input 1
 (change to peer_0 terminal) >>> buy key
>>> buy key 100
>>> buy 1000 coin
(Fault tolerate)
(change to trader_0 terminal) >>> close
(change to trader_0 terminal) >>> buy coin
>>> buy coin 10
(change to trader_0 terminal) sh trader.py
input 0
(change to trader_0 terminal) >>> buy coin
>>> buy coin 10
>>> close

