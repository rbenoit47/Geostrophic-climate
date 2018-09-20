#!/bin/ksh
#
# RB
# 2018
#
#	First compile the code and make the two executables
#
############################################################################
#
GZ2VG=gz2vg.Abs
GZ2VG_log=gz2vg.log
PREP_TABLE=prep_table.Abs
PREP_TABLE_log=prep_table.log
Compile_log=compile.log
#
rm -f *.Abs *.f *.o
#  pas de -fstd89
# librmn
# soit librmn_015.2.a soit librmn_016.2.a
r.compile -src subroutines.ftn gz2vg2.ftn -o $GZ2VG -librmn rmn_016.2 -libappl phy  -libpath .  2>&1 |tee ${Compile_log}
#
rm -f  *.f *.o
#
r.compile -src prep_table.ftn subroutines.ftn -o $PREP_TABLE -librmn rmn_016.2 2>&1 1>>${Compile_log}  #
#
rm -f  *.f *.o
#
echo -e "\nexecutables created"
echo -e "\n======================="
ls -al *.Abs
echo -e "=======================\n"

