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
        self.deposit_limit = 10  # maximum number that each peer could deposit at the trader
        self.buyingthread = dict()
        self.manager = None
        self.vectorclock = [0]
        with open("./logs/log_" + str(self.id) + ".txt", 'w') as file:
            file.write( "Log file for peer " + str(self.id) + "\n")

    def reset_peer(self):
        self.voted = False
        self.trader = None
        #self.active = True

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
            elif msgtype == 'BUY_':
                self.buyingthread[threadID] = msgobj
            elif msgtype == 'VOTE':
                self.response_for_voting(msgtype, msgobj, peerconn)
            elif msgtype == 'DEPO':
                self.send_deposit_to_trader(msgtype, msgobj, peerconn)
            elif msgtype == 'RESG':
                self.respose_for_resigning(msgtype, msgobj)
            elif msgtype == 'MOVE':
                self.trader = msgobj['peer']
                msgobj = {'peer':self.peerid, 'item':dict(self.depositItems.itemdict),'vector':self.vectorclock}
                self.depositItems = Deposit_items()
                peerconn.senddata(msgtype,msgobj)
            elif msgtype == 'SELL':
                self.sellitem(msgtype, msgobj)

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

    def setmyid(self, myid):
        self.peerid = myid

    def startstabilizer(self, stabilizer, delay):
        t = threading.Thread(target = self.__runstabilizer, args = [stabilizer, delay])
        t.start()


    def addNeighborPeer(self, peerid, index, host, port):
        """ Adds a peer name and host:port mapping to the known list of peers. """
        if peerid not in self.neighbors:
            self.neighbors[peerid] = (index, host, int(port))
            return True
        return False

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

    def checklivepeers(self):
        """
        This function attempts to ping all currently live peers to ensure that they are
        still active. It will subsequently remove any peer that it does get a response from
        This function can also be used as a simple stabilizer.
        """
        self.printdebug("CHECKED living neighbors.")
        peerconn = None
        for pid in self.neighbors:
            isconnected = False
            try:
                index, host, port = self.neighbors[pid]
                peerconn = P2PConnection(pid, host, port)
                isconnected = True
            except:
                if isconnected:
                    peerconn.close()
            if peerconn.success:
                peerconn.senddata('PING', None)
                self.printdebug("Connected to living neighbors: " + pid)
            else:
                self.printdebug("Couldn't connect to neighbors: " + pid)

    def vote_election(self):
        """
        Voting: send Election messages to all process with higher Ids and awaits OK messages
        Once messanges are sent, self.voted would be false
        @:return: True if this peer is chosen as Trader, else False
        """
        msgtype = 'VOTE' #find trader
        msgobj = {_MSG: _MSG_ELE, 'peer':self.peerid}
        self.printdebug(self.peerid + " is voting for the trader.")
        isTrader = True
        self.voted = True
        for pid in self.neighbors:
            index, host, port = self.neighbors[pid]
            if index < self.id:
                # ignore peer with lower id
                continue
            resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
            #print resp
            if len(resp) > 0 and resp[0][1][_MSG] == _MSG_OK:
                isTrader = False
        return isTrader

    def vote_won(self):
        """
        Sending other peer 'I won' message and become the Trader
        """
        msgtype = 'VOTE'
        msgobj = {_MSG: _MSG_WON, 'peer':self.peerid}
        #self.printdebug(self.peerid + " won and became the TRADER.")
        self.trader = self.peerid
        for pid in self.neighbors:
            index, host, port = self.neighbors[pid]
            if index > self.id:
                continue
            self.connectandsend(host, port, msgtype, msgobj, waitreply=False)
        self.manager = SellingManager(self.id, self.buyingthread, self)
        self.manager.start()

    def vote_resign(self):
        if self.trader != self.peerid:
            self.printdebug(self.peerid + " is not the trader to resign.")
            return False
        msgtype = 'RESG' #find trader
        msgobj = {_MSG: "I resign as the trader", 'peer':self.peerid}
        self.printdebug(self.peerid + " resign as the TRADER.")
        self.available = False
        self.trader = None
        self.manager.shutdown = True
        for pid in self.neighbors:
            index, host, port = self.neighbors[pid]
            self.connectandsend(host, port, msgtype, msgobj, waitreply=False)

    def respose_for_resigning(self, msgtype, msgobj):
        self.voted = False
        self.printdebug(str(msgobj['peer']) + " resigned. Need to vote a new TRADER.")
        if self.available == False:
            self.printdebug(self.peerid + " is not available and not join to voting trader.")
            return
        if self.vote_election():
            self.printdebug(self.peerid + " won and became the TRADER. Need to get deposit from " +
                            msgobj['peer'])
            index, host, port = self.neighbors[msgobj['peer']]
            msgtype = 'MOVE'
            msgobj = {_MSG: "Please move deposit to me", 'peer':self.peerid}
            resp = self.connectandsend(host, port, msgtype, msgobj, waitreply=True)
            if len(resp) > 0:
                self.depositItems.copy(resp[0][1]['item'])
                self.vectorclock = resp[0][1]['vector']
                self.vectorclock[self.id], self.vectorclock[index] = self.vectorclock[index], self.vectorclock[self.id]
                self.printdebug("Current deposit: " + self.depositItems.toString())
                self.printdebug("Current vectorclock: " + str(self.vectorclock))
            self.vote_won()

    def set_available(self, active=True):
        self.available = active
        if active:
            self.printdebug(self.peerid + " is availbale to serve as the trader.")
        else:
            self.printdebug(self.peerid + " is NOT availbale to serve as the trader.")

    def send_deposit_to_trader(self, msgtype, msgobj, peerconn):
        if self.trader == None:
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

    def get_deposit_from_seller(self, list_of_buyers=list(), item=None):
        msgtype = 'DEPO'
        msgobj = {_MSG: _MSG_UPDATE, 'peer':self.peerid} # update all items message
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
        return is_update

    def lookup(self,item, quan=1):
        """This procedure should search the network; all matching sellers respond to this message with their IDs.
        The hopcount is decremented at each hop and the message is discarded when it reaches 0."""
        if self.peerid == self.trader:
            self.printdebug(self.peerid + " is trader and can't buy or sell items.")
            return
        msgtype = 'LOOK'
        msgobj = { 'peer':self.peerid, 'item':item, 'quan':quan, _MSG:'Buying'}
        self.printdebug(self.peerid + " is LOOKING up for item " + item)
        index, host, port = self.neighbors[self.trader]
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

    def response_for_voting(self, msgtype, msgobj, peerconn):
        self.printdebug(msgobj['peer'] + ' is sending to ' + self.peerid + ': ' + str(msgobj.get(_MSG,'')) + '.')
        if msgobj[_MSG] == _MSG_ELE:
            if self.available == False:
                self.printdebug(self.peerid + " is not available and not join to voting trader.")
                replyobj = {_MSG: ""}
                peerconn.senddata('VOTE',msgobj)
                return
            replyobj = {_MSG: _MSG_OK, 'peer':self.peerid}
            self.printdebug(str(self.peerid)+' is replying to '+str(msgobj['peer'])+' '+str(replyobj[_MSG])+'.')
            peerconn.senddata('VOTE', replyobj)
            if not self.voted and self.vote_election():
                replyobj = {_MSG: _MSG_WON, 'peer':self.peerid}
                self.vote_won()
                self.get_deposit_from_seller()
            return
        if msgobj[_MSG] == _MSG_WON:
            if self.trader == None:
                self.trader = msgobj['peer']
            else:
                new_id = self.neighbors[self.trader][0]
                old_id = self.neighbors[msgobj['peer']][0]
                self.vectorclock[new_id], self.vectorclock[old_id] = self.vectorclock[old_id], self.vectorclock[new_id]
                self.trader = msgobj['peer']

            self.voted = False
            self.printdebug('Current TRADER is ' + self.trader + '. My vote status is ' + str(self.voted))
        #elif msgobj[_MSG] == _MSG_UPDATE:
        #    print _MSG_UPDATE
        #    item = msgobj['item']
        #    self.send_deposit_to_trader(item)


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

    def buyitem(self, item, quan):
        if self.vectorclock[self.neighbors[self.trader][0]] == 0:
            self.vectorclock[self.neighbors[self.trader][0]] = 10000
        if self.peerid == self.trader:
            self.printdebug(self.peerid + " is trader and can't buy or sell items.")
            return
        msgtype = 'BUY_'
        msgobj = {
            'peer':[(self.peerid, self.id, self.host, self.port)],
            'item':item,
            'quan':quan,
            'vector':self.vectorclock
        }
        self.printdebug(self.peerid + " is BUYING " + str(quan) + " " + item + ".")
        index, host, port = self.neighbors[self.trader]
        self.connectandsend(host, port, msgtype, msgobj, waitreply=False)
        return

    def sellitem(self, msgtype, msgobj):
        item = msgobj['item']
        quan = msgobj['quan']
        if quan == 0:
            self.printdebug("The Trader and other trader doesn't have (enough) such item ")
        else:
            self.items[item] += quan
            self.printdebug(self.peerid+" BOUGHT "+str(quan)+" "+item + "."+" from the trader "+self.trader+".")
            self.printdebug("Current items: " + str(self.items))
            self.vectorclock = msgobj['vector']
            self.printdebug("Current vectorclock: " + str(msgobj['vector']))

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

    #def trader_selling(self):

        #manager.start()


