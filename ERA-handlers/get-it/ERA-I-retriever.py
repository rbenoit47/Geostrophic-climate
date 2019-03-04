#!/usr/bin/env python
import calendar as cal
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
"""
   gaspe: 48.8316 N, 64.4869 W
   petite grille 0.75 deg 5x5 points
   centre 48.75, -64.5 largeur/2 et hauteur/2=2*0.75=1.5 ==> 3x3 degres
   area=n/w/s/e:  50.25/-66/47.25/-63
   ip1s = 1000, 850, 700, 500  gz t hr  aux 6 heures
""" 
def retrieve_interim():
    """      
       A function to demonstrate how to iterate efficiently over several years and months etc    
       for a particular interim_request.     
       Change the variables below to adapt the iteration to your needs.
       You can use the variable 'target' to organise the requested data in files as you wish.
       In the example below the data are organised in files per month. (eg "interim_daily_201510.grb")
    """
    yearStart = 1980 #2001
    yearEnd =   1980   #2010
    monthStart = 1
    monthEnd = 12
    for year in list(range(yearStart, yearEnd + 1)):
            startDate = '%04d%02d%02d' % (year, monthStart, 1)
            (weekday,nbdays)=cal.monthrange(year,monthEnd)  # to get nbdays of last month
            lastDate = '%04d%02d%02d' % (year, monthEnd, nbdays)  #30)
            target = "Downloads/gaspe_nohup_%04d.grb" % (year)
            requestDates = (startDate + "/TO/" + lastDate)
            interim_request(requestDates, target)
 
def interim_request(requestDates, target):
    """      
        An ERA interim request for analysis pressure level data.
        Change the keywords below to adapt it to your needs.
        (eg to add or to remove  levels, parameters, times etc)
        Request cost per day is 112 fields, 14.2326 Mbytes
    """
    server.retrieve({
        "class": "ei",
        "stream": "oper",
        "type": "an",
        "dataset": "interim",
        "date": requestDates,
        "expver": "1",
        "levtype": "pl",
        "levelist": "500/700/850/1000",
        "param": "129.128/130.128/157.128",
        "target": target,
        "time": "00/06/12/18",
        "grid": "0.75/0.75",
        "area": "50.25/-66/47.25/-63"
    })
if __name__ == '__main__':
    retrieve_interim()

