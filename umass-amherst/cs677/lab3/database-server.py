#!/usr/bin/python

import socket
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

class Database:
    """ Implements the core functionality that might be used by a peer in a P2P network."""
    def __init__(self, host, port, peerid='server', debug=True):
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
        self.depositItems = Deposit_items()  # deposit items at trader {item:{seller:quantity}}
        #self.initialize()
        self.datalock = False
        #print self.depositItems.toString()
        self.shutdown = False
        self.handlers = {}
        self.datafile = 'logs/database.txt'
        with open("./logs/log_" + str(self.peerid) + ".txt", 'w') as file:
            file.write( "Log file for peer " + str(self.id) + "\n")

    def printdebug(self, msg):
        if self.debug:
            btdebug(msg)
            with open("./logs/log_" + str(self.id) + ".txt", 'a') as file:
                file.write(msg + "\n")

    def initialize(self):
        self.depositItems.put_item_from_seller('Peter', {'item':4})

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
            if msgtype == 'INQU':
                self.response_for_checking(msgtype, msgobj, peerconn)
            elif msgtype == 'PUT_':
                self.response_for_putting(msgtype, msgobj, peerconn)
            elif msgtype == 'GET_':
                self.response_for_getting(msgtype, msgobj, peerconn)
        except KeyboardInterrupt:
            raise
        except:
            if self.debug:
                traceback.print_exc()
        peerconn.close()

    def response_for_checking(self, msgtype, msgobj, peerconn):
        #print msgtype, msgobj
        item, quan = msgobj['item'], msgobj['quan']
        while self.datalock:
            pass
        self.datalock = True
        if self.depositItems.check_itemlist(item,quan):
            replyobj = {'Response': True}
        else:
            replyobj = {'Response': False}
        print self.depositItems.toString(self.datafile)
        self.datalock = False
        peerconn.senddata('RESP', replyobj)

    def response_for_putting(self, msgtype, msgobj, peerconn):
        #print msgtype, msgobj
        itemlist = msgobj['item']
        while self.datalock:
            pass
        self.datalock = True
        self.depositItems.update_itemdict(itemlist)
        replyobj = {'Response': True}
        print self.depositItems.toString(self.datafile)
        self.datalock = False
        peerconn.senddata('RESP', replyobj)

    def response_for_getting(self, msgtype, msgobj, peerconn):
        #print msgtype, msgobj
        item, quan = msgobj['item'], msgobj['quan']
        while self.datalock:
            pass
        self.datalock = True
        if self.depositItems.get_item(item,quan):
            replyobj = {'Response': True}
        else:
            replyobj = {'Response': False}
        print self.depositItems.toString(self.datafile)
        self.datalock = False
        peerconn.senddata('RESP', replyobj)

    def __runstabilizer(self, stabilizer, delay):
        while not self.shutdown:
            stabilizer()
            time.sleep(delay)

    def startstabilizer(self, stabilizer, delay):
        t = threading.Thread(target = self.__runstabilizer, args = [stabilizer, delay])
        t.start()


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
        self.printdebug("Started Database Server: " + self.peerid + "@" + self.host + ":" + str(self.port))

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

class Server(threading.Thread):
    def __init__(self, debug):
        threading.Thread.__init__(self)
        self.myindex = 'server'
        with open('conf/configure_server.txt') as data_file:
            conf = json.load(data_file)
        self.peer = Database(conf['ip'], conf['port'], peerid=conf['id'], debug=debug)
        self.peer.debug = debug
    def run(self):
        self.peer.startserver()

if __name__ == '__main__':
    debug = True
    server = Server(debug=debug)
    server.start()
    while True:
        input = raw_input(">>> ").split()
        if input[0] == 'close':
            server.peer.shutdown = True
            break