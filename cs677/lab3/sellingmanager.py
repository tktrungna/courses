import threading
import timeit
import time
from tradingitem import *

class SellingManager(threading.Thread):
    def __init__(self, index, buyingthread, peer):
        threading.Thread.__init__(self)
        self.buyingthread = buyingthread
        self.active = True
        self.index = index
        self.peer = peer
        self.shutdown = False

    def run(self):
        #print self.buyingthread
        buyingItem = dict()
        while not self.shutdown:
            time.sleep(5)
            if not self.active:
                break
            #print 'ahihi', self.buyingthread
            for id in self.buyingthread.keys():
                #print self.buyingthread[id][0]
                msgobj = self.buyingthread[id]
                item = msgobj['item']
                #print item
                buyingItem[item] = buyingItem.get(item,[])
                buyingItem[item] += [msgobj]
                self.peer.vectorclock[self.peer.id] += 1
                del self.buyingthread[id]

            for item in buyingItem.keys():
                buyers = buyingItem[item]
                buyers.sort(key=lambda x:x['vector'][self.index], reverse=True)
                buyingItem[item] = buyers
                list_of_buyer = [buyer['peer'][0][0] for buyer in buyers]
                for buyer in buyers:
                    msgobj = buyer
                    index, host, port = self.peer.neighbors[msgobj['peer'][0][0]]
                    enough = True
                    #print list_of_buyer
                    while not self.peer.depositItems.check_itemlist(msgobj['item'],msgobj['quan']):
                        if not self.peer.get_deposit_from_seller(list_of_buyer, msgobj['item']):
                            break
                    if not self.peer.depositItems.check_itemlist(msgobj['item'],msgobj['quan']):
                        self.peer.printdebug("The Trader and other seller doesn't have (enough) such item ")
                        msgobj = {'item':msgobj['item'], 'quan':0, 'vector':[]}
                        self.peer.connectandsend(host, port, "SELL", msgobj, waitreply=False)
                        return
                    self.peer.depositItems.get_item(msgobj['item'],msgobj['quan'])
                    self.peer.printdebug("The Trader has selled item " + msgobj['item']+ " to " + msgobj['peer'][0][0] +
                                ". The current quantity of item is: " + str(dict(self.peer.depositItems.itemdict[msgobj['item']])))
                    self.peer.printdebug("Selling " + msgobj['item'] + ' to ' + msgobj['peer'][0][0])
                    self.peer.vectorclock[self.peer.id] += 1
                    replyobj = {'item':msgobj['item'], 'quan':msgobj.get('quan',1), 'vector': self.peer.vectorclock}
                    self.peer.connectandsend(host, port, "SELL", replyobj, waitreply=False)
                del buyingItem[item]