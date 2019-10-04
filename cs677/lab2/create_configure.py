import json
import sys
option = 'local'
quantity = 1500

if len(sys.argv) >= 2:
    if option not in ['local', 'www']:
        print sys.argv[0], 'local/www', 'quantity(integer)'
        exit(1)
    option = sys.argv[1]
if len(sys.argv) == 3:
    if not sys.argv[2].isdigit():
        print sys.argv[0], 'local/www', 'quantity(integer)'
        exit(1)
    quantity = int(sys.argv[2])

localip = '127.0.0.1'
ec2ip = '54.205.71.109'
edlabip = '128.119.243.147'

if option == 'local':
    peers = {
        0:['peter',localip,10040],
        1:['paul',localip,10041],
        2:['marry',localip,10042],
        3:['john',localip,10043],
        4:['paul',localip,10044],
        5:['george',localip,10045],
        6:['ringo',localip,10046],
        7:['barry',localip,10047],
        8:['robin',localip,10048],
        9:['maurince',localip,10049],
    }

elif option == 'www':
    peers = {
        0:['peter',edlabip,10040],
        1:['paul',ec2ip,10041],
        2:['marry',edlabip,10042],
        3:['john',ec2ip,10043],
        4:['paul',edlabip,10044],
        5:['george',ec2ip,10045],
        6:['ringo',edlabip,10046],
        7:['barry',ec2ip,10047],
        8:['robin',edlabip,10048],
        9:['maurince',ec2ip,10049],
    }

connection = {0:[1,2,3,4,5,6,7,8,9],
              1:[0,2,3,4,5,6,7,8,9],
              2:[0,1,3,4,5,6,7,8,9],
              3:[0,1,2,4,5,6,7,8,9],
              4:[0,1,2,3,5,6,7,8,9],
              5:[0,1,2,3,4,6,7,8,9],
              6:[0,1,2,3,4,5,7,8,9],
              7:[0,1,2,3,4,5,6,8,9],
              8:[0,1,2,3,4,5,6,7,9],
              9:[0,1,2,3,4,5,6,7,8]}

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
    9:['camera','newspaper','headphone','sunscreen','painkiller','umbrella','coin','banknote','lipstick']}

num_of_client = 10
file_name = 'conf/configure_'
for i in xrange(num_of_client):
    conf = dict()
    conf['index'] = i
    conf['id'] = peers[i][0].capitalize()+'('+str(i)+')'
    conf['ip'] = peers[i][1]
    conf['port'] = peers[i][2]
    conf['items'] = {it:quantity for it in items[i]}
    conf['neighbors'] = []
    for j in connection[i]:
        neighbor = dict()
        neighbor['index'] = j
        neighbor['id'] = peers[j][0].capitalize()+'('+str(j)+')'
        neighbor['ip'] = peers[j][1]
        neighbor['port'] = peers[j][2]
        conf['neighbors'].append(neighbor)
    with open(file_name+str(i)+'.txt', 'w') as outfile:
        outfile.write(json.dumps(conf))