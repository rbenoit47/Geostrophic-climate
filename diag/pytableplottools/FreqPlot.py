import numpy as np
import matplotlib.pyplot as plt
#
import warnings
warnings.filterwarnings("ignore")
usePolar=False  #because of problem in matplotlib polar plotting
verb=False
saveFigs=False  #important to keep.  gives a hook to set it from outside main
#zz=saveFigs
"""
a problem was encountered in use of polar coordinates plots of matplotlib
even a simple code such as this one:
=======================================================
	#!/usr/bin/env python3
	import numpy as np
	import matplotlib.pyplot as plt
	#
	Ndd=16
	Nuu=10
	theta=np.arange(Ndd)*np.pi*2./Ndd
	freq=np.random.random(Ndd)*100.
	for i in range(Ndd):
		plt.polar([theta[i],theta[i]],[0.,freq[i]],'k')	
	plt.polar(theta, freq,'ro')
	plt.show()
=======================================================
gives this error message:
    result = np.zeros(new_shape, a.dtype)
TypeError: 'numpy.float64' object cannot be interpreted as an index

in meantime, well use a cartesian histogram

thing works with python 3 however but dont want to migrate to 3
"""
#
def wpdf(u,k,c):
	"Weibull pdf function wpdf(u,k,c)"
	pdf=k/c*(u/c)**(k-1.0)*np.exp(-(u/c)**k)
	return pdf
#
def wcdf(u,k,c):
	"Weibull cdf function wcdf(u,k,c)"	
	cdf=(1.0-np.exp(-(u/c)**k))
	return cdf
#
def biFreqPlot(Speeds,Sectors,Freqs):
	"Plot 2d histogram of freqs. biFreqPlot(speeds,freqs)"
	ubins=np.unique(Speeds)
	dbins=np.unique(Sectors)
	# since all elements of Speeds x Sectors are equal to one of ubins x dbins
	#  we want to have H have shape ubins.size x dbins.size
	# thus we have to pass bin edges with a size one more in each direction
	# and offset on each side of ubins to make sure all Speeds are counted in
	udif=np.diff(ubins)
	ddif=np.diff(dbins)
	uedges=ubins[:-1]+udif/2.0
	uedges=np.insert(uedges,0,ubins[0]-udif[0]/2.0)
	uedges=np.append(uedges,ubins[-1]+udif[-1]/2.0)
	if verb: 
		print "ubins:",ubins.size,ubins
		print "uedges:",uedges.size,uedges
	dedges=dbins[:-1]+ddif/2.0
	dedges=np.insert(dedges,0,dbins[0]-ddif[0]/2.0)
	dedges=np.append(dedges,dbins[-1]+ddif[-1]/2.0)
	H, xedges, yedges =np.histogram2d(Speeds,Sectors,bins=[uedges,dedges],
		range=[[uedges[0],uedges[-1]],[dedges[0],dedges[-1]]], 
		weights=Freqs,density=False )  #some numpy dont have density here  density=False, 
	#
	X, Y = np.meshgrid(xedges, yedges)
	plt.pcolormesh(X.transpose(), Y.transpose(), H)
	plt.colorbar()
	plt.ylabel('direction bins')
	plt.xlabel('speed bins')
	plt.title('bi-variate frequencies (%) from WEST table. '  
		'RA source:NCEP \nPeriod:195200-200004 Grid:2.5 deg '
		'Lat: yyy deg  Lon: xxx deg')
	plt.ylim(0.,360.)
	plt.xlim(xedges[0],xedges[-1])
	plt.grid(True)
	plt.xticks(ubins)
	plt.yticks(dbins)
	if saveFigs:
		plt.savefig('bi-variate_freqs.png')
		print 'saved figure bi-variate_freqs.png'
	plt.show()
	if verb: print "H sum",H.sum()
	return H, H.sum(1), H.sum(0)
#
def speedFreqPlot(speeds,freqs):
	"Plot histogram of freqs versus speeds plus weibull fit overlay speedFreqPlot(speeds,freqs)"
	Nuu=speeds.size
	NH=freqs.size
	if verb: print "speeds",Nuu, speeds
	if verb: print "freqs",NH,freqs
	#
	left=np.insert(speeds[:-1],0,0.)  #ajoute 0. a gauche
	right=speeds
	centre=(left+right)/2.0
	width=0.9*(right-left)
	#centre=np.delete(centre,-1)
	if verb: 
		print "left",left.size,left
		print "centre",centre.size,centre
		print "right",right.size,right
		print "width",width.size,width
	plt.bar(left,freqs,width=width)
	plt.grid(True)
	plt.xlabel('speed bins')
	plt.ylabel('speed frequency (%)')
	# fit
	ubar=np.sum(centre*freqs)/np.sum(freqs)
	u2bar=np.sum(centre*centre*freqs)/np.sum(freqs)
	sigma=np.sqrt(u2bar-ubar*ubar)
	if verb: print "ubar,u2bar,sigma",ubar,u2bar,sigma
	k=(sigma/ubar)**(-1.086)  #Justus formula
	c=ubar*(0.568+0.433/k)**(-1.0/k)  #Lysen
	if verb: print "k,c",k,c
	#
	fit=100.*wpdf(centre,k,c)*width
	Hfit=100.*(wcdf(right,k,c)-wcdf(left,k,c))
	if verb: print "100*wpdf",fit
	plt.plot(centre,fit,'r--')
	ax=plt.gca()
	myText='WEIBULL FITS\nvia Lysen and Justus\n''ubar   ='+str("%6.3f"%ubar) \
		+'\nsigmau='+str("%6.3f"%sigma)+'\nc='+str("%6.3f"%c)+'\nk='+str("%6.3f"%k) \
		+'\n-------------\nCurve is from PDF\nDots are from CDF' \
		+'\nSum Bars ='+str("%6.2f"%np.sum(freqs)) \
		+'\nSum Dots ='+str("%6.2f"%np.sum(Hfit)) \
		+'\nSum Curve='+str("%6.2f"%np.sum(fit))
	plt.text(0.70,0.50,myText,transform=ax.transAxes,color='r')
	if verb: 
		print "sum H et fit",np.sum(freqs),np.sum(fit)
		print "cdf right[-1]",wcdf(right[-1],k,c)
	Hfit=100.*(wcdf(right,k,c)-wcdf(left,k,c))
	plt.plot(centre,Hfit,'co')
	#
	if saveFigs:
		plt.savefig('speed_freqs.png')
		print 'saved figure speed_freqs.png'	
	plt.show()
	return
#
def roseFreqPlot(ddbins,Hdd):	
	# for my rose code below see
	# https://matplotlib.org/1.2.1/examples/pylab_examples/polar_bar.html
	# force square figure and square axes looks better for polar, IMO
	if usePolar:
		print "using polar form"
		fig = plt.figure(figsize=(8,8))
		ax = fig.add_axes([0.1, 0.1, 0.8, 0.8], polar=True)
		theta=ddbins/180.*np.pi
		# convert from meteo angle convention to math convention
		theta=90.-theta
		radii=Hdd
		width=np.diff(theta)*0.5
		bars = ax.bar(theta[0:-1], radii, width=width, bottom=0.0)
		for r,bar in zip(radii, bars):
			 bar.set_facecolor( plt.cm.jet(r/10.))
			 bar.set_alpha(0.5)
		plt.title('direction frequencies (%) from WEST table.  '
			'RA source:NCEP \nPeriod:195200-200004 Grid:2.5 deg '
			'Lat: yyy deg  Lon: xxx deg')
		if saveFigs:
			plt.savefig('polar_direction_freqs.png')
			print 'saved figure polar_direction_freqs.png'
		plt.show()
	if not usePolar:
		print "using cartesian form, not polar"
		plt.bar(ddbins[0:-1],Hdd,width=np.diff(ddbins)*0.5)
		plt.xlim(0.,360.)
		plt.xticks(ddbins)
		plt.grid(True)
		plt.xlabel('direction bins')
		plt.ylabel('direction frequency (%)')
		plt.title('direction frequencies (%) from WEST table.  '
			'RA source:NCEP \nPeriod:195200-200004 Grid:2.5 deg '
			'Lat: yyy deg  Lon: xxx deg')
		if saveFigs:
			plt.savefig('direction_freqs.png')
			print 'saved figure direction_freqs.png'
		plt.show()
	#
	return
#
if __name__ == "__main__":
	import pickle
	#
	# Getting back the objects:
	with open('objs.pkl') as f:  # Python 3: open(..., 'rb')
		 ID,Tdd,Tuv,Tf,splitted,Prefix,Sectors,Speeds,Shears = pickle.load(f)
	# delete useless objects
	del(ID,Tdd,Tuv,splitted)
	#
	ubins=np.unique(Speeds)
	dbins=np.unique(Sectors)
	if verb: 
		print "Prefix:",np.unique(Prefix)
		print "ubins:",ubins.size,'\n',ubins
		print "dbins:",dbins.size,'\n',dbins
		print "Shears:",np.unique(Shears)
	dbins360=np.append(dbins,360.)  #equiv to ddbins
	# speed classes from the classification code
	classes = np.array([0.2, 2., 4., 6., 8., 10., 12., 14., 16., 18., 22., \
		26., 30., 34.])
	#
	saveFigs=False
	verb=True
	H,Huu,Hdd=biFreqPlot(Speeds,Sectors,Tf)
	verb=False
	#speedFreqPlot(classes,Huu)
	roseFreqPlot(dbins360,Hdd)

