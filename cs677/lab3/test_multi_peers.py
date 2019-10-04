import threading
from btpeer import *
import timeit
from tradingitem import *
import sys

class Client(threading.Thread):
    def __init__(self, index, debug):
        threading.Thread.__init__(self)
        self.myindex = index
        with open('conf/configure_'+str(index) + '.txt') as data_file:
            conf = json.load(data_file)
        self.peer = BTPeer(conf['id'], conf['index'], conf['ip'], conf['port'], debug=debug)
        self.peer.debug = debug
        self.peer.items = prettyDict(int,conf['items'])
        for n in conf['neighbors']:
            self.peer.addNeighborPeer(n['id'],n['index'],n['ip'],n['port'])
            self.peer.vectorclock += [0]
        self.seller = None

    def run(self):
        self.peer.startserver()

ids = []
if len(sys.argv) == 3:
    ids.append(int(sys.argv[1]))
    ids.append(int(sys.argv[2]))
else:
    ids = map(int,raw_input("Index of client: ").split())
    if len(ids) != 2:
        ids.append(1)
server = Client(ids[0], debug=bool(ids[1]))
server.start()

time.sleep(5000)

server.peer.shutdown = True
time.sleep(100)