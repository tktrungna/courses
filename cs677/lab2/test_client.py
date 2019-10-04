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
    if input[0] == 'vote':
        server.peer.vote_election()
    if input[0] == 'look':
        if len(input) == 1:
            continue
        if len(input) == 3:
            server.peer.seller = server.peer.lookup(input[1], int(input[2]))
        else:
            server.peer.seller = server.peer.lookup(input[1])
    if input[0] == 'resign':
        server.peer.vote_resign()
    if input[0] == 'active':
        active = True
        if len(input) == 2 and input[1] == '0':
            active = False
        server.peer.set_available(active)
    if input[0] == 'buy1000':
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
        if not server.peer.trader:
            print 'Need to vote some one as the trader first!'
        else:
            if len(input) == 3:
                server.peer.buyitem(input[1], int(input[2]))
            else:
                server.peer.buyitem(input[1], 1)
        #print server.peer.items
        server.peer.seller = None