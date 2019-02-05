#!/bin/bash
HEAD=$1    #gaspe_nohup_
EXT=fst
ls $HEAD*
for FST in `ls $HEAD*$EXT`
do
echo $FST
#
YEAR=`echo $FST|sed "s/$HEAD//" |sed "s/\.$EXT//"`
echo $YEAR
for M in {01,02,03,04,05,06,07,08,09,10,11,12}
do
YYYYMM=${YEAR}${M}
ln -sfn $FST $YYYYMM
echo $YYYYMM
done
done
