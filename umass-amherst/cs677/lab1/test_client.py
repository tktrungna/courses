import threading
from btpeer import *
import timeit

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

index = map(int,raw_input("Index of client: ").split())
if len(index) != 2:
    exit()

server = Client(index[0], debug=bool(index[1]))
server.start()

while True:
    input = raw_input(">>> ").split()
    #if input[0] == 'start':
    #    server.start()
    #    continue
    if input[0] == 'close':
        server.peer.shutdown = True
        break
    if input[0] == 'check':
        server.peer.checklivepeers()
    if input[0] == 'look':
        if len(input) == 1:
            continue
        if len(input) == 3:
            server.peer.seller = server.peer.lookup(input[1], int(input[2]))
        else:
            server.peer.seller = server.peer.lookup(input[1])
    if input[0] == 'look1000':
        start = timeit.default_timer()
        for i in xrange(1000):
            if len(input) == 3:
                server.peer.seller = server.peer.lookup(input[1], int(input[2]))
            else:
                server.peer.seller = server.peer.lookup(input[1])
        stop = timeit.default_timer()
        print 'total time:',stop - start
        print 'average time:',(stop - start)/1000
    if input[0] == 'buy':
        if not server.peer.seller:
            print 'Need to find some one has the item first!'
        else:
            server.peer.buyitem(server.peer.seller, input[1])
        print server.peer.items
        server.peer.seller = None