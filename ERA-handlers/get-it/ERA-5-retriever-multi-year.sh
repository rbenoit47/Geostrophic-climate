#!/usr/bin/env bash
# calling sequence arguments:  
# e.g. ERA5-request-multi-year 198103 198205 85 -170 20 -20 2.5 folder-name
# echo nb args $#
doPy=True   #False
#
[ $# -ne 8 ] && echo usage: $0 yyyymm1 yyyymm2 North West South East grid folder && exit 1
yymm1=$1
yymm2=$2
North=$3
West=$4
South=$5
East=$6
grid=$7
folder=$8
#
[ -d $folder ] || mkdir -p $folder
if (( $(echo "$grid < 0.25" | bc -l) )); then
	echo grid $grid must be ge 0.25 
	exit 1
fi
[ $yymm1 -gt $yymm2 ] && echo yymm2, $yymm2 , should be -ge, yymm1, $yymm1.  error && exit 1
#
yy1=`echo "$yymm1/100" | bc`
yy2=`echo "$yymm2/100" | bc`
mm1=`echo "$yymm1 % 100"|bc`
mm2=`echo "$yymm2 % 100"|bc`
# echo $yy1 $mm1 $yy2 $mm2
[ $yy1 -lt 1979 ] && echo begin year must be ge 1979 && exit 1
[ $yy2 -lt 1979 ] && echo end year must be ge 1979 && exit 1
#
for ((yy=$yy1;yy<=$yy2;yy++))
do
#
[ "$yy" -eq "$yy1" ]  && [ "$yy1" -eq "$yy2" ] && m1=$mm1 && m2=$mm2
[[ $yy -eq $yy1  &&  $yy1 -lt $yy2 ]] && m1=$mm1 && m2=12
[[ $yy -gt $yy1  &&  $yy  -lt $yy2 ]] && m1=1 && m2=12
[[ $yy -gt $yy1  &&  $yy  -eq $yy2 ]] && m1=1 && m2=$mm2
#
yyyy=$yy
for ((mm=$m1;mm<=$m2;mm++))
do
echo =========================
echo "=                       ="
echo "= year $yyyy month $mm    ="
echo "=                       ="
echo =========================
#
if [ $doPy == True ]
then
python -W ignore <<FIN
import cdsapi
import calendar as cal
folder='$folder'
yyyy=$yyyy
mm=$mm
mms=str(mm)
j,k=cal.monthrange(yyyy,mm)
dd=range(1,k+1)
dds=[]
for e in dd:
	dds.append(str(e))
#
outname=folder+'/ERA5-'+folder+'-'+str(yyyy)+mms.zfill(2)+'.grib'
#
c = cdsapi.Client()
c.retrieve("reanalysis-era5-pressure-levels",
	{
		'variable':['geopotential','relative_humidity','temperature'],
		'pressure_level':['500','700','850','1000'],
		'product_type':'reanalysis',
		'year':str(yyyy),
		'month':mms.zfill(2),
		'day': dds,
		'time':['00:00','06:00','12:00','18:00'],
		'area': '${North}/${West}/${South}/${East}',
		'grid': '${grid}/${grid}' , # east-west and north-south resolution
		'format':'grib'
	},  outname)
#	
"""
D'autre part, avec python on a pu etablir 
les coordonnees des coins de la maille NA de 61x27 points:
sud-ouest: 20N, 170W
nord-est:  85N, 20W
"""
FIN
fi
#
done
done
