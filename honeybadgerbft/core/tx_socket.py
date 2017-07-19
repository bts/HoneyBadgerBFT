import socket
import os

def bind_datagram_socket(path):
    # Make sure the socket doesn't already exist:
    try:
        os.unlink(path)
    except OSError:
        if os.path.exists(path):
            raise

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    sock.bind(path)

    return sock

class TxSocket():
    def __init__(self, sock, encode, decode, max_size):
        self.socket = sock
        self.connected = False
        self.encode = encode
        self.decode = decode
        self.max_size = max_size

    def write(self, txes):
        # assert self.connected # We assume we read before writing

        if txes != ():
            self.socket.send(self.encode(txes))

    def read(self):
        payload, sender = self.socket.recvfrom(self.max_size)
        if not self.connected:
            self.socket.connect(sender)
            self.connected = True

        txes = self.decode(payload)
        return txes

def bind_codec_socket(path, encode, decode, max_size=655360000):
    return TxSocket(bind_datagram_socket(path), encode, decode, max_size)
