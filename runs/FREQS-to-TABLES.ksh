#!/bin/ksh
#
# RB
# 2018
# set -x
#
. CLASSIF-parms.dot  #to get our parameters
#

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
DATADIR=${OUTDIR}/${atlas}  #RB this line was missing. potential bug if not ANU
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
$PREP_TABLE 2>&1  <<______EOF   |tee -a ${Processing_log}
${atlas}
${i1} ${i2} ${di}
${j1} ${j2} ${dj}
${ifile2}
${DATADIR}
${ofile2}
______EOF
#  
done

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
#
echo -e '\n\n >> DONE!<< \n\n'
rm prep_table.txt class_settings*.*
rm -r ${OUTDIR}/*/*/*.txt  #txt form of the tables
###
