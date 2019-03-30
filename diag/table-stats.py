#!/usr/bin/env python2
import numpy as np
import os , sys
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings("ignore")
#
try:
	import FreqPlot as ptt #our own plot tools speedFreqPlot
except:
	print "module FreqPlot not found"
	print "make sure that folder holding our FreqPlot module is on the PYTHONPATH env variable"
	quit()
#
import pickle
#
# speed classes from the classification code
classes = np.array([0.2, 2., 4., 6., 8., 10., 12., 14., 16., 18., 22., 26., 30., 34.])
#
verb=False #True
saveFigs=False #True
half=0.5
third=1./3.
#
def getTableData(TableFile):
	T= np.loadtxt(TableFile,skiprows=2,usecols=[1,2,4])
	ID=np.loadtxt(TableFile,skiprows=2,usecols=[0],dtype='|S12')  
	#handle text part separately... easier
	#  |S12 is the proper descriptor for a 12-char string
	Tdd=T[:,0]
	Tuv=T[:,1]
	Tf =T[:,2]
	Tm1=np.average(Tuv**1,weights=Tf)
	Tm2=np.average(Tuv**2,weights=Tf)
	TsumF=np.sum(Tf)
	return ID,Tdd,Tuv,Tf
def splitTableID(ID):
	# split the 12 char long elements of ID into its components
	# e.g. ANU1D045C10M  is ANU1 D 045 C 10 M
	N=np.size(ID)
	if verb: print N
	splitID=np.chararray((N, 4),itemsize=4)
	for i in range(N):
		idi=ID[i]
		prefix=idi.__getslice__(0,4)
		ddbin= idi.__getslice__(5,8)
		uvbin= idi.__getslice__(9,11)
		shear= idi.__getslice__(11,12)
		splitID[i,:]=[prefix,ddbin,uvbin,shear]
	if verb: print idi,prefix,ddbin,uvbin,shear
	return splitID
#
def plot_table(Tf,Sectors,Speeds,Shears):
	ddClass=np.unique(Sectors)
	uuClass=np.unique(Speeds)
	ddbins=np.append(ddClass,min(360.,ddClass[-1]-ddClass[-2]+ddClass[-1]))
	if verb: print "dd bins:", ddbins
	#
	H,Huu,Hdd=ptt.biFreqPlot(Speeds,Sectors,Tf)
	if verb: 
		print "H shape",H.shape
		print 'Huu:',Huu
		print 'Hdd:',Hdd
	#
	ptt.speedFreqPlot(classes,Huu)
	#
	ptt.roseFreqPlot(ddbins,Hdd)
	#
	return #H, xedges, yedges
#
ptt.saveFigs=saveFigs
WESTpath="./WESTtables"
jWEST=list(range(54,55)) #59+1))
iWEST=list(range(116,117)) #121+1))
if not ptt.usePolar:
	print '\nPLEASE NOTE THAT THE PLOT ON DIRECTIONAL FREQS\n' \
	'is NOT DONE ON POLAR COORDINATES DUE TO A MATPLOTLIB BUG\n' \
	'when fix to bug is known, just switch usePolar to True in code\n\n'
for j in jWEST:
	for i in iWEST:
		if verb:print WESTpath,j,i
		WESTjpath= os.path.join(WESTpath,str(j))
		WESTjifile=os.path.join(WESTjpath, str(i) +"_table.ef")
		# 
		ID,Tdd,Tuv,Tf=getTableData(WESTjifile)
		print WESTpath,j,i,ID[0],np.sum(Tf)/100.
		#
		splitted=splitTableID(ID)
		Prefix=splitted[:,0]
		Sectors=np.array(splitted[:,1]).astype(np.float)
		Speeds=np.array(splitted[:,2]).astype(np.float)
		Shears=splitted[:,3]
		#
		plot_table(Tf,Sectors,Speeds,Shears)
#
if verb:
	print Prefix
	print Sectors
	print Speeds
	print Shears
	print Tf
	#
	print np.unique(Sectors)
	print np.unique(Speeds)
#
# Saving the objects:
#with open('objs.pkl', 'w') as f:
#    pickle.dump([ID,Tdd,Tuv,Tf,splitted,Prefix,Sectors,Speeds,Shears], f)

