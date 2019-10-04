import threading
from btpeer import *
import timeit
import sys

class Client(threading.Thread):
    def __init__(self, index, debug):
        threading.Thread.__init__(self)
        self.myindex = index
        with open('conf/configure_'+str(index) + '.txt') as data_file:
            conf = json.load(data_file)
        self.peer = BTPeer(0, conf['id'], conf['ip'], conf['port'],debug=debug)
        self.peer.debug = debug
        self.peer.items = conf['items']
        for n in conf['neighbors']:
            self.peer.addNeighborPeer(n['id'],n['ip'],n['port'])
        self.seller = None

    def run(self):
        self.peer.startserver()

index = int(sys.argv[1])

server = Client(index, debug=False)
server.start()

time.sleep(5)

start = timeit.default_timer()
for i in xrange(1000):
    server.peer.seller = server.peer.lookup('scissors',10)
stop = timeit.default_timer()
print index, 'total time:',stop - start,'average time:',(stop - start)/1000

time.sleep(500)

server.peer.shutdown = True