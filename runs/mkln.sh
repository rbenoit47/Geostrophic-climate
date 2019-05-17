HEAD=$1  # header of the fst filenames  e.g. ERA5-Gaspe-
EXT=$2   # extension of the fst files including the dot  e.g. .fst
ACT=$3   # action to be done: link or unlink
#
if [[ $ACT = "link" ]]; then
	FILES=`ls $HEAD*$EXT`
	LISTE=  #to initialize the LISTE of links to be created
	for FILE in $FILES
	do
	#echo file: $FILE
	SHORT=`echo -n $FILE | sed "s/$HEAD//" |sed "s/$EXT//"`
	#echo short: $SHORT
	#echo -n $SHORT | wc -c
	#ensure SHORT is positive integer with 6 digits
	NSHORT=`echo -n $SHORT | wc -c`
	if [[ $SHORT =~ ^[0-9]+$ && $NSHORT == "6" ]]; then
		ln -sfn $FILE $SHORT
	else
		echo $FILE "is not properly named. Adjust to ${HEAD}YYYYMM${EXT} format"
		exit -1
	fi
	LISTE="$LISTE $SHORT"
	done
	echo $LISTE > zzzmkln.txt
fi
if [[ $ACT = "unlink" ]]; then
	LISTE=`cat zzzmkln.txt`
	#echo LISTE:$LISTE
	rm $LISTE zzzmkln.txt
fi
