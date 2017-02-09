#!/usr/bin/env python

try:
    import vrep
except:
    print ('--------------------------------------------------------------')
    print ('"vrep.py" could not be imported. This means very probably that')
    print ('either "vrep.py" or the remoteApi library could not be found.')
    print ('Make sure both are in the same folder as this file,')
    print ('or appropriately adjust the file "vrep.py"')
    print ('--------------------------------------------------------------')
    print ('')

vrep.simxFinish(-1)
clientID = vrep.simxStart('127.0.0.1', 19997, True, True, 500, 5)

if clientID != -1:
    print('Connected to remote API Server')
else:
    print "[WARN] Could not connect to remote API server"
    print "VREPQuery object not created successfully"

vrep.simxSynchronous(clientID, True)



vrep.simxSynchronousTrigger(clientID)