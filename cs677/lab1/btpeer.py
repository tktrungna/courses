#!/usr/bin/python

import socket
import threading
import time
import traceback
import random
import json
from time import gmtime, strftime
from p2pconnection import P2PConnection

def btdebug(msg):
    print strftime("[ %Y-%m-%d %H:%M:%S ]", gmtime()), msg

class BTPeer:
    """ Implements the core functionality that might be used by a peer in a P2P network."""
    def __init__(self, maxpeers, peerid, host, port, debug=True):
        self.maxpeers = int(maxpeers)
        self.port = int(port)
        self.host = host
        self.peerid = peerid
        self.peerlock = threading.Lock()
        self.neighbors = {}
        self.shutdown = False
        self.handlers = {}
        self.items = list()
        self.debug = debug

    def __debug(self, msg):
        if self.debug:
            btdebug(msg)

    def __handlepeer(self, clientsock):
        """
        handlepeer(new socket connection) ->()
        Dispatches messages from the socket connection
        """
        host, port = clientsock.getpeername()
        peerconn = P2PConnection(None, host, port, clientsock)
        try:
            msgtype, msgobj = peerconn.recvdata()
            #print msgtype, msgobj
            if msgtype == 'LOOK':
                self.response_for_looking_up(msgtype, msgobj, peerconn)
            elif msgtype == 'BUY_':
                self.sellitem(msgobj,peerconn)
        except KeyboardInterrupt:
            raise
        except:
            if self.debug:
                traceback.print_exc()
        #self.__debug('Disconnecting ' + str(clientsock.getpeername()))
        peerconn.close()

    def __runstabilizer(self, stabilizer, delay):
        while not self.shutdown:
            stabilizer()
            time.sleep(delay)

    def setmyid(self, myid):
        self.peerid = myid

    def startstabilizer(self, stabilizer, delay):
        """ Registers and starts a stabilizer function with this peer.
        The function will be activated every <delay> seconds.
        """
        t = threading.Thread(target = self.__runstabilizer, args = [stabilizer, delay])
        t.start()


    def addNeighborPeer(self, peerid, host, port):
        """ Adds a peer name and host:port mapping to the known list of peers. """
        if peerid not in self.neighbors and(self.maxpeers == 0 or
                         len(self.neighbors) < self.maxpeers):
            self.neighbors[peerid] = (host, int(port))
            return True
        else:
            return False

    def sendtopeer(self, peerid, msgtype, msgobj, waitreply=True):
        """
        sendtopeer(peer id, message type, message data, wait for a reply) -> [(reply type, reply data), ...]
        Send a message to the identified peer. In order to decide how to send the message, the router handler
        for this peer will be called. If no router function has been registered, it will not work. The router
        function should provide the next immediate peer to whom the message should be forwarded. The peer's reply,
        if it is expected, will be returned.
        Returns None if the message could not be routed.
        """
        if peerid not in self.neighbors:
            return None
        host, port = self.neighbors[peerid]
        return self.connectandsend(host, port, msgtype, msgobj, pid=peerid, waitreply=waitreply)

    def connectandsend(self, host, port, msgtype, msgobj, pid=None, waitreply=True):
        """
        connectandsend(host, port, message type, message data, peer id,
        wait for a reply) -> [(reply type, reply data), ...]
        Connects and sends a message to the specified host:port. The host's
        reply, if expected, will be returned as a list of tuples.
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

    def checklivepeers(self):
        """ Attempts to ping all currently known peers in order to ensure that they are still active.
        Removes any from the peer list that do not reply. This function can be used as a simple stabilizer.
        """
        self.__debug("CHECKED living neighbors.")
        todelete = []
        peerconn = None
        for pid in self.neighbors:
            isconnected = False
            try:
                host,port = self.neighbors[pid]
                peerconn = P2PConnection(pid, host, port)
                isconnected = True
            except:
                if isconnected:
                    peerconn.close()

            if peerconn.success:
                peerconn.senddata('ping', None)
                self.__debug("Connected to living neighbors: " + pid)
            else:
                self.__debug("Couldn't connect to neighbors: " + pid)


    def lookup(self,item,hopcount=3):
        """this procedure should search the network; all matching sellers respond to this message with their IDs.
        The hopcount is decremented at each hop and the message is discarded when it reaches 0."""
        msgtype = 'LOOK'
        msgobj = {
            'peer':[(self.peerid,self.host,self.port)],
            'item':item,
            'hopcount':hopcount
        }
        self.__debug(self.peerid + " is LOOKING up for item " + item)
        list_seller = set([])
        for pid in self.neighbors:
            host, port = self.neighbors[pid]
            resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
            for r in resp:
                obj = r[1]
                for p in obj['peer']:
                    list_seller.add(tuple(p))
        list_seller = list(list_seller)
        if not list_seller:
            self.__debug("Unfortunately, no one in this village has the item he need.")
            return None
        else:
            self.__debug("Luckily, these sellers have the item he need: " + str(list_seller))
            for seller in list_seller:
                if seller[0] not in self.neighbors:
                    self.addNeighborPeer(*seller)
            selected_index = random.randrange(len(list_seller))
            self.__debug(self.peerid+" choose this seller to buy the item he need: " + str(list_seller[selected_index]))
            return list_seller[selected_index]

    def response_for_looking_up(self, msgtype, msgobj, peerconn):
        self.__debug(msgobj['peer'][0][0] + ' is looking up for ' + msgobj['item'] + '.')
        if msgobj['item'] in self.items: #check if looking up item is exist
            replyobj = {'peer':[(self.peerid,self.host,self.port)]}
            self.__debug(self.peerid + " has item " + msgobj['item'] + " and ready to sell.")
            peerconn.senddata('AVAI', replyobj)
            return
        if msgobj['hopcount'] > 1:
            msgobj['peer'].append([str(self.peerid),str(self.host),str(self.port)])
            msgobj['hopcount'] -= 1
            response = self.forwardlook(msgtype, msgobj)
            list_seller = []
            for reply in response:
                list_seller.extend(reply[1]['peer'])
            if not response:
                self.__debug("None of my neighbors has item " + msgobj['item'] + " for selling.")
                peerconn.senddata(None, None)
            else:
                self.__debug("These neighbors have item " + msgobj['item'] + " for selling." + str(list_seller))
                peerconn.senddata('AVAI', {'peer':list_seller})
        else:
            self.__debug("Looking up message from " + msgobj['peer'][0][0] + " is discarded!")
            peerconn.senddata(None, None)

    def forwardlook(self, msgtype, msgobj):
        self.__debug(self.peerid + " FORWARDED message from " + msgobj['peer'][0][0] + '.')
        skip_list = set([p[0] for p in msgobj['peer']])
        #print skip_list
        response = []
        for pid in self.neighbors:
            if pid in skip_list:
                continue
            host, port = self.neighbors[pid]
            for reply in self.connectandsend(host, port, msgtype, msgobj, waitreply=True):
                response += reply,
        #print "RESPONSE", response
        return response

    def buyitem(self, peer, item):
        msgobj = {'peer':[self.peerid, self.host, self.port], 'item':item}
        resp = self.connectandsend(peer[1], peer[2], 'BUY_', msgobj, waitreply=True)[0]
        if resp and resp[0] == 'SELL' and resp[1]['item'] == item:
            self.items += item,

            self.__debug(self.peerid + " BOUGHT " + item + " successfully!")
        else:
            self.__debug(self.peerid + " BOUGHT " + item + " unsuccessfully!")
        self.__debug("New items list: " + str(self.items))

    def sellitem(self, msgobj, peerconn):
        if msgobj['peer'][0] not in self.neighbors:
            host, port = msgobj['peer'][1], msgobj['peer'][1]
            self.addNeighborPeer(msgobj['peer'][0],host,port)
            self.__debug("ADDED buyer " + msgobj['peer'][0] + "to neighbors list.")
            #print self.neighbors
        if msgobj['item'] in self.items:
            self.items.remove(msgobj['item'])
            peerconn.senddata('SELL', msgobj)
            self.__debug("SELLED " + msgobj['item'] + " successfully.")
            self.__debug("New items list: " + str(self.items))
        else:
            peerconn.senddata(None, None)
            self.__debug("SELLED " + msgobj['item'] + " unsuccessfully.")

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
        self.__debug("Started client of " + self.peerid + "@" + self.host + ":" + str(self.port) + '\n' +
                     "Has items: " + str(self.items) + ".\nHas connection with " + str(self.neighbors))
        while not self.shutdown:
            try:
                clientsock, clientaddr = s.accept()
                clientsock.settimeout(10)
                t = threading.Thread(target = self.__handlepeer, args = [clientsock])
                t.start()
            except KeyboardInterrupt:
                print 'KeyboardInterrupt: stopping server'
                self.shutdown = True
                continue
            except:
                continue
        s.close()

