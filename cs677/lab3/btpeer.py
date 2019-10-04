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
trader_ids = ['trader_0', 'trader_1']

def btdebug(msg):
    print strftime("[ %Y-%m-%d %H:%M:%S ]", gmtime()), msg

class BTPeer:
    """ Implements the core functionality that might be used by a peer in a P2P network."""
    def __init__(self, peerid, id, host, port, debug=True):
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
        self.items = prettyDict()     # items the peer has: {item:number}
        self.trader = None      # peerid of the trader
        self.available = True   # available to serve as the trader
        self.voted = False      # during election, True of the peer has sent election message
        self.depositItems = Deposit_items()  # deposit items at trader {item:{seller:quantity}}
        self.deposit_limit = 100  # maximum number that each peer could deposit at the trader
        self.buyingthread = dict()
        self.manager = None
        self.deposited = False
        self.vectorclock = [0]
        with open("./logs/log_" + str(self.id) + ".txt", 'w') as file:
            file.write( "Log file for peer " + str(self.id) + "\n")

    def printdebug(self, msg):
        if self.debug:
            btdebug(msg)
            with open("./logs/log_" + str(self.id) + ".txt", 'a') as file:
                file.write(msg + "\n")


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
                """
                elif msgtype == 'BUY_':
                    self.buyingthread[threadID] = msgobj
                elif msgtype == 'VOTE':
                    self.response_for_voting(msgtype, msgobj, peerconn)
                """
            elif msgtype == 'DEPO':
                #print msgtype, msgobj, self.deposited, msgobj.get('initialized',False)
                if self.deposited and not msgobj.get('initialized',False):
                    pass
                else:
                    self.send_deposit_to_trader(msgtype, msgobj, peerconn)
                    self.deposited = True
                """
                elif msgtype == 'RESG':
                    self.respose_for_resigning(msgtype, msgobj)
                elif msgtype == 'MOVE':
                    self.trader = msgobj['peer']
                    msgobj = {'peer':self.peerid, 'item':dict(self.depositItems.itemdict),'vector':self.vectorclock}
                    self.depositItems = Deposit_items()
                    peerconn.senddata(msgtype,msgobj)
                elif msgtype == 'SELL':
                    self.sellitem(msgtype, msgobj)
                """
            elif msgtype == 'CONN':
                #print msgtype, msgobj
                self.trader = [msgobj['peer'], msgobj['ip'], msgobj['port']]
                self.printdebug("The current trader is: " + str(self.trader[0]))
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

    def send_deposit_to_trader(self, msgtype, msgobj, peerconn):
        if self.trader[0] != msgobj.get('peer'):
            return
        msgtype = 'DEPO'
        item = msgobj.get('item')
        if item != None:
            itemlist = {item:min(self.deposit_limit, self.items[item])}
            self.items[item] -= min(self.deposit_limit, self.items[item])
            self.printdebug(self.peerid + " is updating " + item + " to the trader. Current quantity of " +
                            item + " is " + str(self.items[item]))
        else:
            itemlist = {i:min(self.deposit_limit, self.items[i]) for i in self.items}
            #print itemlist
            for i in self.items:
                self.items[i] -= min(self.deposit_limit, self.items[i])
            self.printdebug("Current items: " + str(self.items))
            self.printdebug(self.peerid + " is depositing item to the trader.")
        msgobj = {
            'peer':self.peerid,
            'item':itemlist,
        }
        peerconn.senddata(msgtype, msgobj)
        #index, host, port = self.neighbors[self.trader]
        #self.connectandsend(host, port, msgtype, msgobj, waitreply=False)

    def lookup(self,item, quan=1):
        """This procedure should search the network; all matching sellers respond to this message with their IDs.
        The hopcount is decremented at each hop and the message is discarded when it reaches 0."""
        if self.peerid == self.trader:
            self.printdebug(self.peerid + " is trader and can't buy or sell items.")
            return
        msgtype = 'LOOK'
        msgobj = { 'peer':self.peerid, 'item':item, 'quan':quan, _MSG:'Buying'}
        self.printdebug(self.peerid + " is LOOKING up for item " + item)
        index, host, port = self.trader
        #print index, host, port
        resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
        if len(resp) == 0:
            return
        if resp[0][1].get('item',0) > 0:
            self.printdebug(self.peerid + " bought item from the trader.")
            self.items[item] += resp[0][1].get('item',0)
        else:
            self.printdebug("The Trader and other seller doesn't have (enough)" + item + '.')
        self.printdebug("Current items: " + str(self.items))
        return

    def response_for_looking_up(self, msgtype, msgobj, peerconn):
        #print msgobj
        self.printdebug(msgobj['peer'] + ' is looking up for ' + msgobj['item'] + '.')
        if self.peerid != self.trader:
            peerconn.senddata('AVAI', {'peer':[]})
            return
        list_of_buyer = [msgobj['peer']]
        while not self.depositItems.check_itemlist(msgobj['item'],msgobj['quan']):
            if not self.get_deposit_from_seller(list_of_buyer, msgobj['item']):
                break
        if not self.depositItems.check_itemlist(msgobj['item'],msgobj['quan']):
            self.printdebug("The Trader and other seller doesn't have (enough) such item ")
            peerconn.senddata('AVAI', {'peer':[]})
            return
        #if not self.depositItems.get_item(msgobj['item'],msgobj.get('quan',1)): #check if looking up item is exist in deposit
        #    self.get_deposit_from_seller(list_of_buyer, msgobj['item'])
        #    if not self.depositItems.get_item(msgobj['item'],msgobj.get('quan',1)):
        #        self.printdebug("The Trader and other seller doesn't have (enough) such item ")
        #        peerconn.senddata('AVAI', {'peer':[]})
        #        return
        self.depositItems.get_item(msgobj['item'],msgobj['quan'])
        replyobj = {'peer':[(self.peerid,self.host,self.port)],'item':msgobj.get('quan',1)}
        self.printdebug("The Trader has selled item " + msgobj['item'] + " to " + msgobj['peer'] +
                     ". The current quantity of item is: " + str(dict(self.depositItems.itemdict[msgobj['item']])))
        peerconn.senddata('AVAI', replyobj)

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
        self.printdebug("Started client of " + self.peerid + "@" + self.host + ":" + str(self.port) + '\n' +
                     "Has items: " + str(self.items))# + ".\nHas connection with " + str(self.neighbors))
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