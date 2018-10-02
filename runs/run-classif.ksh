#!/bin/ksh
#
# RB
# 2018
#
# 	Four parts to execute:
#
#   a)  GZ2VG  ..computes the Vg frequencies
#	generates a newclas file (one class per line) and a classes*.fst file
#   b)  Process classes*.fst for PREP_TABLE.
#	This is achieved by using two RMNLIB utilities: editfst and pgsm
#   c)	PREP_TABLE .. generates the tables from newclas and classes*.fst
#	tables are in files tables.txt
#   d)  perl converts the tables.txt into final formal for WEST: tables.ef
#
#############################################################################
GZ2VG=gz2vg.Abs
PREP_TABLE=prep_table.Abs
Processing_log=processing.log
PATH=.:$PATH
#
# Input directory of the climate data base
INDIR=/home/rbenoit/classification/runs/NCEP-NA-sample
# Result directory
Here=`pwd`
OUTDIR=$Here/outdir
rm -rf $OUTDIR
mkdir $OUTDIR
# choose season: either one of the following or "ANU" for annual
#season='DJF MAM JJA SON'
season='ANU'
Grid_i1=1
Grid_i2=61  #5 #28
Grid_di=1
Grid_j1=1
Grid_j2=27  #4 #27
Grid_dj=1
#
#
# create seasons in OUTDIR
for s in $season
do
   echo '================================'
   echo 'Processing season ' $s
   echo '================================'
   DATADIR=${OUTDIR}/${s}
   if [ ! -d ${DATADIR} ] ; then
      mkdir ${DATADIR}
   fi
#
# gridsettings and define parameters
   cat > class_settings.nml.${s} <<___EOF
&grid_cfg
`cat grids/classification_settings.nml | sed 's/\&grille//'`
/
&gz2vg_cfg
 season = '${s}', version = 1
 ip1s = 1000, 850, 700, 500
 height = 0., 1500., 3000., 5500.
 method = 'hydrostatic'
 shearvec = .false. 
 byear = 2001, bmonth = 01, bday = 01, bhour = 00, sampling = 6
 eyear = 2001, emonth = 02, eday = 28, ehour = 18
 region = ''
 indir = '${INDIR}'
 outdir = '${DATADIR}'
 ofile = 'classes_${s}.fst'
 swtt = .true., swph = .true.
 nofc = .false., noms = .false. 
 nsect = 16
 nclass = 14
 classes = 0.2, 2., 4., 6., 8., 10., 12., 14., 16., 18., 22., 26., 30., 34.
 generalclas = .true.
 flat_s = -5., flat_n = 10.
/
___EOF
#
   ln -sf class_settings.nml.${s} class_settings.nml
#
echo '================================'
echo 'doing 1st executable ' $GZ2VG 'see log file '$Processing_log
echo '================================'
$GZ2VG 2>&1 | tee ${Processing_log}
done
exit
#
#############
# to echo commands:  set -x
#########
echo '=================================='
echo 'doing 2nd executable ' $PREP_TABLE 'see log file '$Processing_log
echo '=================================='
#grid values, number of gridpoints -1
i1=${Grid_i1}
i2=${Grid_i2}
di=${Grid_di}
j1=${Grid_j1}
j2=${Grid_j2}
dj=${Grid_dj}
#define output directories for table files
for atlas in ${season}
do
#
ifile2=${DATADIR}/classes_${atlas}.fst
ofile2=classes.txt
k=${i1}
echo '=================================================='
echo 'Generate the folders to output the tables.ef array'
echo '=================================================='
while [ ${k} -le ${i2} ]
do
   ii=`echo $ii $k`
   echo $ii
   k=`expr $k + ${di}`
done
k=${j1}
while [ ${k} -le ${j2} ]
do
   jj=`echo $jj $k`
   echo $jj
   k=`expr $k + ${dj}`
done
echo $ii
echo $jj
#########
#
for j in ${jj}; do
   mkdir ${DATADIR}/${j}
done
#
echo '========================================================'
echo 'Processing '${ifile2} '\n ... see log file '$Processing_log
echo '========================================================'
#get lat and lon for the header 
ip1=`r.fstliste -izfst ${ifile2} -nomvar FREQ -col 15 | awk '{print $1}'`
ip2=`r.fstliste -izfst ${ifile2} -nomvar FREQ -col 16 | awk '{print $1}'`
ip3=`r.fstliste -izfst ${ifile2} -nomvar FREQ -col 17 | awk '{print $1}'`

pgsm -iment ${ifile2} -ozsrt ${DATADIR}/lalo.std -i 2>&1 | tee -a ${Processing_log} <<EOF
   sortie( std, 2000, R )
   grille( tape1, ${ip1}, ${ip2}, ${ip3} ) 
   heure(0)
   outlalo( ${ip1}, ${ip2}, ${ip3}, 'LA', 'LO' )
   end
EOF
#
voir -iment ${ifile2} | grep LA
flag_la=$?
voir -iment ${ifile2} | grep LO
flag_lo=$?
flag=`expr $flag_la + $flag_lo`
if [ ${flag} -ne 0 ]; then
   editfst -s  ${DATADIR}/lalo.std -d ${ifile2} -i 2>&1 1 | tee -a ${Processing_log}  <<___EOF
      desire(-1,['LA','LO'])
      end
___EOF
fi
# generates the table.txt files
#
echo '=================================='
echo 'doing 2nd executable ' $PREP_TABLE 'see log file '$Processing_log
echo '=================================='
$PREP_TABLE 2>&1 |tee -a ${Processing_log} <<______EOF
${atlas}
${i1} ${i2} ${di}
${j1} ${j2} ${dj}
${ifile2}
${DATADIR}
${ofile2}
______EOF
#
echo 'using perl to obtain final table at point '
for j in ${jj}; do
   for i in ${ii}; do
      tname=${DATADIR}/${j}/${i}_table.ef
      #
      ### Prepare table.ef for simulation
      #
      echo -n $j'/'$i', '  #no newline here
      #
      cat > prep_table.txt << ______EOF
${DATADIR}/${j}/${i}_${ofile2} ${tname}
______EOF
      # generates the table.ef files
      perl prep_table.pl
      #
   done
done
#
done
echo '\n\n >> DONE!<< \n\n'
rm prep_table.txt class_settings*.*
###
