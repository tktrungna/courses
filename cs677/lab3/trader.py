#!/usr/bin/python

import socket
import sys
import threading
import time
import traceback
import random
import json
from time import gmtime, strftime
from p2pconnection import P2PConnection
from tradingitem import *
from sellingmanager import *

_MSG_OK = 'OK'
_MSG_ELE = 'Election'
_MSG_WON = 'I won'
_MSG = 'Msgstr'
_MSG_UPDATE = 'Update Deposit'

def btdebug(msg):
    print strftime("[ %Y-%m-%d %H:%M:%S ]", gmtime()), msg

class Trader:
    """ Implements the core functionality that might be used by a peer in a P2P network."""
    def __init__(self, host, port, peerid, debug=True):
        """
        The constructor for a peer
        :param peerid: ID of the peer
        :param host: host ip address of the peer
        :param port: port to wait connection of the peer
        :param debug: debug option
        :return:
        """
        self.peerlock = threading.Lock()
        self.debug = debug
        self.port = int(port)   # port of the peer
        self.host = host        # ip address of the peer
        self.peerid = peerid    # username of the peer, which should be unique
        self.id = id            # index of the peer, for election vote
        self.neighbors = {}     # neighborof the peer {peerid:[index,host,port]}
        self.shutdown = False
        self.handlers = {}
        self.other_trader = []
        self.depositItems = Deposit_items()
        self.cache = prettyDict(lambda: 0)
        self.cacheLimit = 10
        self.myindex = -1
        with open("./logs/log_" + str(self.peerid) + ".txt", 'w') as file:
            file.write( "Log file for peer " + str(self.id) + "\n")

    def printdebug(self, msg):
        if self.debug:
            btdebug(msg)
            with open("./logs/log_" + str(self.peerid) + ".txt", 'a') as file:
                file.write(msg + "\n")

    def addNeighborPeer(self, peerid, index, host, port):
        """ Adds a peer name and host:port mapping to the known list of peers. """
        if peerid not in self.neighbors:
            self.neighbors[peerid] = (index, host, int(port))
            return True
        return False

    def __handlepeer(self, clientsock, threadID):
        """
        The handlepeer function takes care of making a new socket connection
        and dispatching messages from that connection
        """
        #print threadID
        #print self.threaddict
        host, port = clientsock.getpeername()
        peerconn = P2PConnection(None, host, port, clientsock)
        try:
            msgtype, msgobj = peerconn.recvdata()
            if msgtype == 'LOOK':
                self.response_for_looking_up(msgtype, msgobj, peerconn)
            elif msgtype == 'PUT_':
                self.buyingthread[threadID] = msgobj
            elif msgtype == 'GET_':
                self.response_for_voting(msgtype, msgobj, peerconn)
        except KeyboardInterrupt:
            raise
        except:
            if self.debug:
                traceback.print_exc()
        peerconn.close()

    def __runstabilizer(self, stabilizer, delay):
        while not self.shutdown:
            stabilizer()
            time.sleep(delay)

    def startstabilizer(self, stabilizer, delay):
        t = threading.Thread(target = self.__runstabilizer, args = [stabilizer, delay])
        t.start()

    def get_deposit_from_seller(self, list_of_buyers=list(), item=None, initialized=False):
        msgtype = 'DEPO'
        msgobj = {_MSG: _MSG_UPDATE, 'peer':self.peerid, 'initialized':initialized} # update all items message
        if item != None:
            msgobj['item'] = item
        self.printdebug(self.peerid + " is asking deposit items from sellers.")
        is_update = False
        for pid in self.neighbors:
            if pid in list_of_buyers:
                continue
            index, host, port = self.neighbors[pid]
            resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
            if len(resp) == 0:
                continue
            rplobj = resp[0][1]
            itemlist = rplobj['item']
            total = sum([itemlist[item] for item in itemlist])
            if total > 0:
                is_update = True
            #print itemlist
            seller = rplobj['peer']
            self.depositItems.put_item_from_seller(seller, itemlist)
        self.printdebug("Current deposit: " + self.depositItems.toString())
        self.deposit_items(self.depositItems.itemdict)
        self.depositItems.delete()
        self.printdebug("Current deposit: " + self.depositItems.toString())
        return is_update

    def get_item_from_database(self, item):
        # get self.cachelimit more items from database
        if not self.check_item(item,self.cacheLimit):
            return False
        self.get_item(item,self.cacheLimit)
        self.cache[item] += self.cacheLimit
        return True

    def put_item_from_cache_to_database(self):
        for item in self.cache.keys():
            self.put_item(item,self.cache[item])
            del self.cache[item]

    def get_allitem_from_database(self, item):
        while self.check_item(item,1):
            self.depositItems.get_item(item,1)
            self.cache[item] += 1

    def response_for_looking_up(self, msgtype, msgobj, peerconn):
        #print msgtype, msgobj
        self.printdebug(msgobj['peer'] + ' is looking up for ' + msgobj['item'] + '.')
        list_of_buyer = [msgobj['peer']]
        #print list_of_buyer, self.check_item(msgobj['item'],msgobj['quan'])
        while not self.check_item(msgobj['item'],msgobj['quan']):
            #print "check_item"
            if not self.get_deposit_from_seller(list_of_buyer, msgobj['item'], initialized=True):
                break
        if not self.check_item(msgobj['item'],msgobj['quan']):
            self.printdebug("The Trader and other seller doesn't have (enough) such item ")
            peerconn.senddata('AVAI', {'peer':[]})
            return
        # get item and put to cache

        while self.cache[msgobj['item']] <= msgobj['quan']:
            self.get_item_from_database(msgobj['item'])
        #print self.cache
        self.cache[msgobj['item']] -= msgobj['quan']
        self.depositItems.get_item(msgobj['item'],msgobj['quan'])
        replyobj = {'peer':[(self.peerid,self.host,self.port)],'item':msgobj.get('quan',1)}
        self.printdebug("The Trader has selled item " + msgobj['item'] + " to " + msgobj['peer'] +
                     ". The current quantity of item is: " + str(self.cache))
        peerconn.senddata('AVAI', replyobj)
        #print self.cache

    def sendtopeer(self, peerid, msgtype, msgobj, waitreply=True):
        """
        Sends a message to an identified peer.
        """
        if peerid not in self.neighbors:
            return None
        index, host, port = self.neighbors[peerid]
        return self.connectandsend(host, port, msgtype, msgobj, pid=peerid, waitreply=waitreply)

    def connectandsend(self, host, port, msgtype, msgobj, pid=None, waitreply=True):
        """
        Connects and sends a message to the specified host:port. The host's
        reply will be returned as a list of tuples.
        """
        msgreply = []
        onereply = None
        try:
            peerconn = P2PConnection(pid, host, port)
            peerconn.senddata(msgtype, msgobj)
            if waitreply:
                onereply = peerconn.recvdata()
            while(onereply !=(None,None)):
                msgreply.append(onereply)
                onereply = peerconn.recvdata()
            peerconn.close()
        except KeyboardInterrupt:
            raise
        except:
            if self.debug:
                traceback.print_exc()
        return msgreply

    def makeserversocket(self, port, backlog=5):
        """ Constructs and prepares a server socket listening on the given port. """
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('', port))
        s.listen(backlog)
        return s

    def startserver(self):
        s = self.makeserversocket(self.port)
        s.settimeout(2)
        self.printdebug("Started Trader: " + self.peerid + "@" + self.host + ":" + str(self.port))
        self.threadid = 0
        while not self.shutdown:
            try:
                clientsock, clientaddr = s.accept()
                clientsock.settimeout(10)
                self.threadid += 1
                t = threading.Thread(target = self.__handlepeer, args = [clientsock] + [self.threadid])
                t.start()
            except KeyboardInterrupt:
                print 'KeyboardInterrupt: stopping server'
                self.shutdown = True
                continue
            except:
                continue
        s.close()

    def check_item(self, item, quan=1):
        msgtype = 'INQU'
        msgobj = {_MSG: 'Checking', 'item':item, 'quan':quan}
        host = self.neighbors['server']['ip']
        port = self.neighbors['server']['port']
        resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
        #print resp[0][1]
        return resp[0][1]['Response']

    def put_item(self, item, quan=1):
        msgtype = 'PUT_'
        msgobj = {_MSG: 'Putting', 'item':{item:{self.peerid:quan}}}
        host = self.neighbors['server']['ip']
        port = self.neighbors['server']['port']
        resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
        #print resp

    def get_item(self, item, quan=1):
        msgtype = 'GET_'
        msgobj = {_MSG: 'Getting', 'item':item, 'quan':quan}
        host = self.neighbors['server']['ip']
        port = self.neighbors['server']['port']
        resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
        #print resp

    def deposit_items(self, itemlist):
        msgtype = 'PUT_'
        msgobj = {_MSG: 'Putting', 'item':itemlist}
        host = self.neighbors['server']['ip']
        port = self.neighbors['server']['port']
        resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
        #print resp

    def check_other_trader(self):
        #print 'check_other_trader'
        time.sleep(30)
        resend_new_trader = False
        while not self.shutdown:
            time.sleep(10)
            #print 'check_other_trader'
            peerconn = None
            isconnected = False
            try:
                pid, host, port = self.other_trader
                #print pid, host, port
                peerconn = P2PConnection(pid, host, port)
                isconnected = True
            except:
                if isconnected:
                    peerconn.close()
            if peerconn.success:
                peerconn.senddata('PING', None)
                #self.printdebug("Connected to other trader: " + pid)
                resend_new_trader = False
            else:
                self.printdebug("Couldn't connect to other trader: " + pid)
                if not resend_new_trader:
                    self.broadcast_to_nonneighbor()
                    resend_new_trader = True

    # send "i am trader to neighbor
    def broadcast_to_neighbor(self):
        msgtype = 'CONN'
        msgobj = {_MSG: "I am your trader", 'peer':self.peerid, 'ip':self.host, 'port':self.port}
        for pid in self.neighbors:
            if pid == 'server':
                continue
            index, host, port = self.neighbors[pid]
            if index%2 != self.myindex:
                continue
            resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=False)

    # send "i am trader to neighbor
    def broadcast_to_nonneighbor(self):
        msgtype = 'CONN'
        msgobj = {_MSG: "I am your new trader", 'peer':self.peerid, 'ip':self.host, 'port':self.port}
        for pid in self.neighbors:
            if pid == 'server':
                continue
            index, host, port = self.neighbors[pid]
            if index%2 == self.myindex:
                continue
            #print index, host, port
            resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=False)


class TraderThread(threading.Thread):
    def __init__(self, id, debug, initialized=True):
        threading.Thread.__init__(self)
        self.myindex = 'server'
        with open('conf/configure_trader_' + str(id) + '.txt') as data_file:
            conf = json.load(data_file)
        self.peer = Trader(conf['ip'], conf['port'], peerid=conf['id'], debug=debug)
        for i,n in enumerate(conf['neighbors']):
            n['index'] = i
            self.peer.addNeighborPeer(n['id'],n['index'],n['ip'],n['port'])
        self.peer.neighbors['server'] = conf['server']
        self.peer.debug = debug
        self.peer.myindex = conf['index']
        self.peer.other_trader = conf['other_trader']
        self.peer.broadcast_to_neighbor()
        self.peer.get_deposit_from_seller(initialized=initialized)


        #self.peer.deposit_items(self.peeritemlist):
    def run(self):
        self.peer.startserver()

class CheckingThread(threading.Thread):
    def __init__(self, server):
        threading.Thread.__init__(self)
        self.server = server
    def run(self):
        self.server.peer.check_other_trader()


if __name__ == '__main__':
    debug = True
    ids = []
    if len(sys.argv) == 3:
        ids.append(int(sys.argv[1]))
        ids.append(int(sys.argv[2]))
    else:
        ids = map(int,raw_input("Index of trader: ").split())
        if len(ids) != 2:
            ids.append(1)
    server = TraderThread(ids[0], debug=True, initialized=bool(ids[1]))
    server.start()
    checkingThread = CheckingThread(server)
    checkingThread.start()
    while True:
        input = raw_input(">>> ").split()
        if input[0] == 'close':
            server.peer.put_item_from_cache_to_database()
            server.peer.shutdown = True
            break
        if len(input) > 0 and input[0] == 'check':
            item = 'item' if len(input) == 1 else input[1]
            quan = 1 if len(input) <= 2 or (len(input) == 3 and not input[1].isdigit()) else int(input[2])
            server.peer.check_item(item, quan)
            pass
        if len(input) > 1 and input[0] == 'add':
            quan = 1 if len(input) == 2 or not input[2].isdigit() else int(input[2])
            item = input[1]
            server.peer.put_item(item, quan)
        if len(input) > 1 and input[0] == 'del':
            quan = 1 if len(input) == 2 or not input[2].isdigit() else int(input[2])
            item = input[1]
            server.peer.get_item(item, quan)