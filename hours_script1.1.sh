#!/bin/bash

######################
#
# Hardcoded variables and static variables
#
#######################

########## All time cards will be saved in this directory, so make sure its there first ###
test -d ./Daily_Hours
if [ "$?" = "1" ]
	then
		mkdir ./Daily_Hours
fi


# Hardcoded variables for expediency
TODAY=`date --rfc-3339=ns | cut -d " " -f 1`
PAYCODE="MGHPCC/INTERN"
EMERGENCY="Y"
BILLABLE="N"
NAME="mludwig"
THISMONTH=`echo $TODAY | cut -d "-" -f 2`
THISDAY=`echo $TODAY | cut -d "-" -f 3`

test -e ./Daily_Hours/${TODAY}_hours.txt
if [ $? = 0 ]
	then
		touch ./Daily_Hours/${TODAY}_hours.txt
fi
TESTID=0
NEGCHECK=0
MOVEON=0
APPENDER=0

##########################
#
#       FUNCTIONS
#
############################

#correct format func

Format_func(){
while [[ $INPUT != ??:?? ]] || [[ -n ${INPUT//[0-9,:]/} ]] 2>/dev/null
	do
		read -p "Please enter the time you came in, in this format: \"16:45\" " INPUT
done
((MOVEON++))
}

HourFormat_func(){
HOURSCHECK=`echo $INPUT | cut -d ":" -f 1`
while [[ $HOURSCHECK -gt 24 ]] || [[ -n ${INPUT//[0-9,:]/} ]] 2>/dev/null
	do
		
		printf "You must enter the hours in 24 hour format with no letters. Try again.\n"
		read -p "Enter the time you came in, in this format: \"16:45\"  " INPUT
		HOURSCHECK=`echo $INPUT | cut -d ":" -f 1`
done
((MOVEON++))
}

MinuteFormat_func(){
MINSCHECK=`echo $INPUT | cut -d ":" -f 2`
if [[ $MINSCHECK = 0? ]]
	then 
		MINSCHECK=`echo $MINSCHECK | cut -c 1`
	fi
while [[ $MINSCHECK -gt 60 ]] || [[ -n ${INPUT//[0-9,:]/} ]] 2>/dev/null
	do
		printf "The minutes you entered in your punch in time\nare a letter or over 60, that is not possible. Try again.\n"
		read -p "Please enter the time you came in, in this format: \"16:45\"   " INPUT
		MINSCHECK=`echo $INPUT | cut -d ":" -f 2`
	done
((MOVEON++))
}

RoundUp_func(){
MINUTE=`echo $1 | cut -d ":" -f 2`
if [[ $MINUTE = 0? ]]
	then 
		MINUTES=`echo $MINUTE | cut -c 1`
	else
		MINUTES=$MINUTE
fi

# Round up the punch in time minutes to the nearest 15 minutes
if [[ $MINUTES -ge 0 ]] && [[ $MINUTES -le 7 ]]
	then
		MINUTESCORRECT=00 

elif [[ $MINUTES -ge 8 ]] && [[ $MINUTES -le 22 ]]
	then
		MINUTESCORRECT=15

elif [[ $MINUTES -ge 23 ]] && [[ $MINUTES -le 37 ]]
	then
		MINUTESCORRECT=30

elif [[ $MINUTES -ge 38 ]] && [[ $MINUTES -le 52 ]]
	then
		MINUTESCORRECT=45
else
		MINUTESCORRECT="00"
		HOURPLUS=1
		
fi

}
CheckIfNeg_func(){ 
INHOUR=`echo $1 | cut -d ":" -f 1`
OUTHOUR=`echo $2 | cut -d ":" -f 1`
TESTHOUR=$((OUTHOUR - INHOUR))
if [[ $TESTHOUR -le -1 ]] 
	then

		printf "That clockout time is before your clock in time\! Try again. \n"
		read -p "What time did you clock out? " INPUT
	else
		NEGCHECK=1
fi
}
TestPreviousInput_func(){
TESTID=0
LASTTIME=`tail -n 1 ./Daily_Hours/${TODAY}_hours.txt | cut -d "|" -f 5`
LASTHOUR=`echo $LASTTIME | cut -d ":" -f 1`
LASTMIN=`echo $LASTMIN | cut -d ":" -f 2`
CURRENTHOUR=`echo $1 | cut -d ":" -f 1`
CURRENTMIN=`echo $1 | cut -d ":" -f 2`
HOURTEST=$((CURRENTHOUR - LASTHOUR))
if [[ $LASTMIN = 0? ]]
	then 
		LASTMIN=`echo $LASTMIN | cut -c 1`
fi
if [[ $CURRENTMIN = 0? ]]
	then 
		CURRENTMIN=`echo $CURRENTMIN | cut -c 1`
fi
MINTEST=$((CURRENTMIN - LASTMIN))
if [[ $HOURTEST -le 00 ]] && [[ $MINTEST -le 00 ]]
	then
		printf "You could not have come back before you left\!\n"
		read -p "Try again: " INPUT
	else
		TESTID=1
fi		
}


#########  MAIN()   ##################

printf "\n"
echo -e "\e[1m\e[32mMGHPCC Intern Time Clock for MLudwig w\\ email return\e[0m" 
printf "\n"
printf "You can enter as many sets of clock in and outs as you like\n"
printf "Type \"quit\" if you dont need to use this.\n"
read -p "What time did you clock in? (Use XX:XX Format): " INPUT
while [[ "$INPUT" != "quit" ]] 2>/dev/null ############# Input Loop Start ###########
	do
############## Clock in time ######################
		while [[ $MOVEON -ne 3 ]]	&& [[ $TESTID -ne 1 ]]
			do
				Format_func
				HourFormat_func
				MinuteFormat_func
				TestPreviousInput_func $INPUT
		done
		MOVEON=0
		TIMEINHOUR=`echo $INPUT | cut -d ":" -f 1`		
		RoundUp_func $INPUT
		TIMEINMIN="$MINUTESCORRECT"
		if [[ $HOURPLUS -eq 1 ]]
			then
				((TIMEINHOUR++))
		fi
		HOURPLUS=0
		TIMEIN="$INPUT"
#################### Clock out time ###############
		read -p "What time did you clock out? " INPUT
		while [ $MOVEON -ne 3 ] && [ $NEGCHECK -ne 1 ] 2>/dev/null
			do
				Format_func
				HourFormat_func
				MinuteFormat_func
				CheckIfNeg_func $TIMEIN $INPUT
		done

		TIMEOUTHOUR=`echo $INPUT | cut -d ":" -f 1`		
		RoundUp_func $INPUT
		TIMEOUTMIN="$MINUTESCORRECT"
		if [ $HOURPLUS -eq 1 ]
			then
				((TIMEOUTHOUR++))
		fi
		TIMEOUT="$INPUT"
		MOVEON=0
		HOURPLUS=0

####### What done #######
	read -p "What did you do in that time? " WHATDONE
	printf "\n"
		
########## here lie dragons #########

	WORKHOUR=$((TIMEOUTHOUR - TIMEINHOUR))
	WORKMIN=$((TIMEOUTMIN - TIMEINMIN))
	case $WORKMIN in
		-15) WORKMIN="45"
			((WORKHOUR--))	;;
		-30) WORKMIN="30"
			((WORKHOUR--))	;;
		-45) WORKMIN="15"
			((WORKHOUR--))	;;
			0) WORKMIN="00"	;;
			*)							;;
	esac
	TESTID=0

	FINALWORKHOURS=`echo "$WORKHOUR"":""$WORKMIN"`
	OUTPUT="$NAME|$TODAY|"$TIMEIN"|$TODAY|$TIMEOUT|$FINALWORKHOURS|$PAYCODE|$BILLABLE|$EMERGENCY|$WHATDONE"
	printf "$OUTPUT\n" >> ./Daily_Hours/${TODAY}_hours.txt
	printf "$OUTPUT"
	printf "\n"
	read -p "Ok, do you have another set to input? (Y/N)" INPUT
	while [ "$INPUT" != "Y" ] && [ "$INPUT" != "N" ] 2>/dev/null
		do
			read -p "Please enter \"Y\" for \"yes\" and \"N\" for \"no\" " INPUT
	done
	if [ "$INPUT" = "N" ]
		then
			break
	fi
	
	read -p "What time did you clock in? " INPUT
done ############# Input loop end ###################

ADDHOURS=0
ADDMINS=0
test -e ./Monthly_Hours/${THISMONTH}_hours.txt
if [ $THISDAY -eq 26 ] && [ $? = 0 ]
	then
		mv ./Monthly_Hours/${THISMONTH}_hours.txt ./Monthly_Hours/${THISMONTH}_hours.arch
fi
test -e ./Monthly_Hours/${THISMONTH}_hours.txt
if [ $? -eq 1 ]
	then
		touch ./Monthly_Hours/${THISMONTH}_hours.txt
	else
		RUNNINGTOTAL=`cat ./Monthly_Hours/${THISMONTH}_hours.txt`
		RUNNINGHOURS=`echo $RUNNINGTOTAL | cut -d ":" -f 1`
		RUNNINGMIN=`echo $RUNNINGTOTAL | cut -d ":" -f 2`
		((ADDHOURS=ADDHOURS+RUNNINGHOURS))
		((ADDMINS=ADDMINS+RUNNINGMIN))
fi

while read f
	do
		INPUTHOURS=`echo $f | cut -d "|" -f 6`
		HOURS=`echo $INPUTHOURS | cut -d ":" -f 1`
		MINS=`echo $INPUTHOURS | cut -d ":" -f 2`
		((ADDHOURS=ADDHOURS+HOURS))
		((ADDMINS=ADDMINS+MINS))
		if [[ $ADDMINS -ge 60 ]]
			then
				((ADDHOURS++))
				((ADDMINS=ADDMINS-60))
		fi
done < ./Daily_Hours/${TODAY}_hours.txt



case $ADDMINS in
	00) EMAILMIN="0"  ;;
	15) EMAILMIN="25"  ;;
	30) EMAILMIN="5"  ;;
	45) EMAILMIN="75"  ;;
	*) ;;
esac
EMAILVAR=`echo "$ADDHOURS"".""$EMAILMIN"`

TOTALHOURS=`echo "$ADDHOURS"":""$ADDMINS"`
echo $TOTALHOURS > ./Monthly_Hours/${THISMONTH}_hours.txt


EMAILBODY=`cat ./Daily_Hours/${TODAY}_hours.txt`
printf "$EMAILBODY" | mail -s "Hours for Morgan, $TODAY Total:$EMAILVAR" mludwig@techsquare.com







