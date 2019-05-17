#!/bin/ksh
#
# RB
# 2018
set -x
#
. CLASSIF-parms.dot  #to get our parameters
#
# to create YYYYMM links if needed
if [[ $LINKIT = '1' ]] ; then
	Here=`pwd`
	cd $INDIR
	$Here/mkln.sh $HEAD $EXT link
	cd $Here
fi
# [[ -e $OUTDIR   ]]
rm -rf $OUTDIR
mkdir $OUTDIR
#
cat > /dev/null <<FIN
echo OUTDIR=$OUTDIR
rm -rf $OUTDIR
mkdir $OUTDIR
ls -al $OUTDIR
exit
FIN
#
# create seasons in OUTDIR
for s in $season
do
   echo '================================'
   echo 'Processing season ' $s
   echo '================================'
   DATADIR=${OUTDIR}/${s}
   if [ ! -d ${DATADIR} ] ; then
      mkdir -p ${DATADIR}
   fi
#

   cat class_settings.gen |sed "s/_season_/${s}/" > class_settings.nml.${s}

   ln -sf class_settings.nml.${s} class_settings.nml
#
   echo '================================'
   echo 'doing 1st executable ' $GZ2VG 'see log file '$Processing_log
   echo '================================'
   $GZ2VG 2>&1 | tee ${Processing_log}

done
#
if [[ $LINKIT = '1' ]] ; then
	cd $INDIR
	$Here/mkln.sh $HEAD $EXT unlink
	cd $Here
fi

