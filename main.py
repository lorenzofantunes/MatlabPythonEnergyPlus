# Created by Lorenzo F. Antunes(lorenzofantunes or lfantunes)
# 20/07/2016
# Pelotas, Brazil

#!/usr/bin/env python
import socket


#create the socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('localhost', 10000))
s.listen(1)

print "Starting Simulation:"
conn, addr = s.accept()

while True:
    #receive values from matlab
    data = conn.recv(1024)

    if not data:
        break

    #do whatever you want to
    print data

    #send values to matlab
    openings = [0.5, 0.1, 0, 1, 1, 1, 1, 0.9] #random values
    openingsStr = ', '.join(str(e) for e in openings) #convert vector to string, values separeted by comma
    conn.sendall(openingsStr) #send data

conn.close()
