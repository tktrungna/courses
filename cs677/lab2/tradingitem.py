from collections import defaultdict
import pprint

class prettyDict(defaultdict):
    def __init__(self, *args, **kwargs):
        defaultdict.__init__(self,*args,**kwargs)

    def __repr__(self):
        return str(dict(self))

class Item:
    def __init__(self, name, quan):
        self.name = name
        self.quan = quan

class Deposit_items:
    def __init__(self):
        self.itemdict = prettyDict(lambda: prettyDict(lambda: 0))

    def copy(self, pdict):
        #print pdict
        self.itemdict = prettyDict(lambda: prettyDict(lambda: 0))
        for item in pdict:
            for seller in pdict[item]:
                self.itemdict[item][seller] = int(pdict[item][seller])

    def toString(self):
        return str(dict(self.itemdict))

    def check_item(self, item):
        if item in self.itemdict:
            return

    def put_item(self, item, seller, quan):
        self.itemdict[item][seller] += quan

    def put_item_from_seller(self, seller, itemlist):
        for item in itemlist:
            self.itemdict[item][seller] += itemlist[item]

    def get_item(self, item, quan):
        avai_quan = sum([self.itemdict[item][seller] for seller in self.itemdict[item]])
        if quan > avai_quan:
            return False
        for seller in self.itemdict[item]:
            get_quan = min(self.itemdict[item][seller], quan)
            self.itemdict[item][seller] -= get_quan
            quan -= get_quan
            if quan == 0:
                break
        return True

    def check_itemlist(self, item, quan):
        avai_quan = sum([self.itemdict[item][seller] for seller in self.itemdict[item]])
        if quan > avai_quan:
            return False
        for seller in self.itemdict[item]:
            get_quan = min(self.itemdict[item][seller], quan)
            #self.itemdict[item][seller] -= get_quan
            quan -= get_quan
            if quan == 0:
                break
        return True

# test
if __name__ == '__main__':
    dep = Deposit_items()
    dep.put_item('soup', 'trung', 2)
    dep.put_item('soup', 'phuong', 3)
    dep.put_item('soup-hehe', 'trung', 2)
    print dep.itemdict
    print dep.get_item('soup', 1)
    print dep.itemdict
    print dep.get_item('soup', 2)
    print dep.itemdict
    print dep.get_item('soup', 1)
    print dep.itemdict
    dep.put_item_from_seller('trung',{'a':2, 'b':4})
    dep.put_item_from_seller('phuong',{'c':2, 'b':4})
    print dep.itemdict
