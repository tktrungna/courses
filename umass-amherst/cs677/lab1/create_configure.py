import json
import sys
if sys.argv[1] == 'local':
    peers = {
        0:['peter','127.0.0.1',10040],
        1:['paul','127.0.0.1',10041],
        2:['marry','127.0.0.1',10042],
        3:['john','127.0.0.1',10043],
        4:['paul','127.0.0.1',10044],
        5:['george','127.0.0.1',10045],
        6:['ringo','127.0.0.1',10046],
        7:['barry','127.0.0.1',10047],
        8:['robin','127.0.0.1',10048],
        9:['maurince','127.0.0.1',10049],
    }

elif sys.argv[1] == 'www':
    peers = {
        0:['peter','128.119.243.164',10040],
        1:['paul','128.119.243.164',10041],
        2:['marry','128.119.243.164',10042],
        3:['john','128.119.243.164',10043],
        4:['paul','54.147.232.101',10044],
        5:['george','54.147.232.101',10045],
        6:['ringo','54.147.232.101',10046],
        7:['barry','54.147.232.101',10047],
        8:['robin','54.147.232.101',10048],
        9:['maurince','54.147.232.101',10049],
    }

#0:['peter','128.119.243.164',2000],
#1:['paul','54.147.232.101',2001],

connection = {0:[1,2],
              1:[0,2,3],
              2:[0,1,4],
              3:[1,5],
              4:[2,5,6],
              5:[3,4,6,7],
              6:[4,5,7],
              7:[5,6,8,9],
              8:[7],
              9:[7]}


items = {
    0:['diary','bottle','water','packet','tissue', 'glasses', 'watch'],
    1:['photo','camera','stamp','pordcard','dictionary','coin'],
    2:['brush','key','phone','scissors'],
    3:['wallet','button','umbrella','pen','pencil','lighter'],
    4:['cigarette','purse','case','clip'],
    5:['scissors','rubber'],
    6:['comb','notebook','laptop','mirror','toothbrush','battery'],
    7:['bulb','newspaper','magazine','clock','pencil'],
    8:['rice','meat','milk','phone','scissors'],
    9:['camera','newspaper','headphone','sunscreen','painkiller','umbrella','coin','banknote','lipstick']
}

num_of_client = 10
file_name = 'conf/configure_'
for i in xrange(num_of_client):
    conf = dict()
    conf['id'] = peers[i][0].capitalize()+'('+str(i)+')'
    conf['ip'] = peers[i][1]
    conf['port'] = peers[i][2]
    conf['items'] = items[i]
    conf['neighbors'] = []
    for j in connection[i]:
        neighbor = dict()
        neighbor['id'] = peers[j][0].capitalize()+'('+str(j)+')'
        neighbor['ip'] = peers[j][1]
        neighbor['port'] = peers[j][2]
        conf['neighbors'].append(neighbor)
    with open(file_name+str(i)+'.txt', 'w') as outfile:
        outfile.write(json.dumps(conf))