#!/usr/bin/env bash
# calling sequence arguments:  year North West South East grid folder
# e.g. ERA5-request-year 1981 85 -170 20 -20 2.5
#echo nb args $#
[ $# -ne 7 ] && echo usage: $0 year North West South East grid folder &&exit 1
yyyy=$1
North=$2
West=$3
South=$4
East=$5
grid=$6
folder=$7
#
[ -d $folder ] || mkdir -p $folder
if (( $(echo "$grid < 0.25" | bc -l) )); then
	echo grid $grid must be ge 0.25 
	exit 1
fi
[ $yyyy -lt 1979 ] && echo year must be ge 1979 && exit 1
#
for mm in {01..12}
do
echo =========================
echo "=                       ="
echo "= year $yyyy month $mm    ="
echo "=                       ="
echo =========================
#
python -W ignore <<FIN
#!/usr/bin/env python
import cdsapi
import calendar as cal
j,k=cal.monthrange($yyyy,$mm)
dd=range(1,k+1)
dds=[]
for e in dd:
	dds.append(str(e))
c = cdsapi.Client()
c.retrieve("reanalysis-era5-pressure-levels",
	{
		'variable':['geopotential','relative_humidity','temperature'],
		'pressure_level':['500','700','850','1000'],
		'product_type':'reanalysis',
		'year':'${yyyy}',
		'month':'${mm}',
		'day': dds,
		'time':['00:00','06:00','12:00','18:00'],
		'area'    : '${North}/${West}/${South}/${East}', #'85/-170/20/-20', # North, West, South, East. Default: global
		'grid'    : '${grid}/${grid}' ,  #'2.5/2.5', # Lat/lon grid: east-west (longitude) and north-south resolution (latitude)
		'format':'grib'
	},
	"${folder}/ERA5-${yyyy}${mm}.grib")
#	
"""
D'autre part, avec python on a pu etablir 
les coordonnees des coins de la maille NA de 61x27 points:
sud-ouest: 20N, 170W
nord-est:  85N, 20W
"""
FIN

done
