import socket
import struct
import json


class P2PConnection:
    def __init__(self, peerid, host, port, sock=None):
        self.id = peerid
        self.success = True
        if not sock:
            self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            try:
                self.s.connect((host, int(port)))
            except:
                self.success = False
                return
        else:
            self.s = sock
        self.sd = self.s.makefile('rw', 0)

    def __makemsg(self, msgtype, msgdata):
        msglen = len(msgdata)
        msg = struct.pack("!4sL%ds" % msglen, msgtype, msglen, msgdata)
        return msg

    def senddata(self, msgtype, msgobj):
        """
        senddata(message type, message data) -> boolean status
        Send a message through a peer connection. Returns True on success or False if there was an error.
        """
        msgdata = json.dumps(msgobj)
        try:
            msg = self.__makemsg(msgtype, msgdata)
            self.sd.write(msg)
            self.sd.flush()
        except KeyboardInterrupt:
            raise
        except:
            return False
        return True

    def recvdata(self):
        """
        recvdata() ->(msgtype, msgdata)
        Receive a message from a peer connection. Returns(None, None) if there was any error.
        """
        try:
            msgtype = self.sd.read(4)
            if not msgtype:
                return(None, None)
            lenstr = self.sd.read(4)
            msglen = int(struct.unpack("!L", lenstr)[0])
            msg = ""
            while len(msg) != msglen:
                data = self.sd.read(min(2048, msglen - len(msg)))
                if not len(data):
                    break
                msg += data
            if len(msg) != msglen:
                return(None, None)
        except KeyboardInterrupt:
            raise
        except:
            return(None, None)
        msgobj = json.loads(msg)
        return(msgtype, msgobj)

    def close(self):
        self.s.close()
        self.s = None
        self.sd = None