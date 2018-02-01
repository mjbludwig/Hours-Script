#!/bin/bash

######
#		Ask for input time in/time out and spit out print the formatted result
#	to screen, file and then email it to myself! 
#
#		All of the variables that don't change are hard coded including the email the 
#	result is sent to.
#
#
######
#correct format func
MOVEON=0
Format_func(){
while [[ $INPUT != ??:?? ]] || [[ -n ${INPUT//[0-9,:]/} ]] 2>/dev/null
	do
		read -p "Please enter the time you came in, in this format: \"16:45\"  " INPUT
done
((MOVEON++))
if [ $MOVEON -gt 3 ]
	then
		MOVEON=0
fi
}

HourFormat_func(){
HOURSCHECK=`echo $INPUT | cut -d ":" -f 1`
while [ $HOURSCHECK -gt 24 ] || [[ -n ${INPUT//[0-9,:]/} ]] 2>/dev/null
	do
		printf "You must enter the hours in 24 hour format with no letters. Try again.\n"
		read -p "Enter the time you came in, in this format: \"16:45\"  " INPUT
		HOURSCHECK=`echo $INPUT | cut -d ":" -f 1`
done
((MOVEON++))
if [ $MOVEON -gt 3 ]
	then
		MOVEON=0
fi
}

MinuteFormat_func(){
MINSCHECK=`echo $INPUT | cut -d ":" -f 2`
while [ $MINSCHECK -gt 60 ] || [[ -n ${INPUT//[0-9,:]/} ]] 2>/dev/null
	do
		printf "The minutes you entered in your punch in time\nare a letter or over 60, that is not possible. Try again.\n"
		read -p "Please enter the time you came in, in this format: \"16:45\"   " INPUT
		MINSCHECK=`echo $INPUT | cut -d ":" -f 2`
	done
((MOVEON++))
if [ $MOVEON -gt 3 ]
	then
		MOVEON=0
fi
}
RoundUp_func(){
MINUTES=`echo $1 | cut -d ":" -f 2`

# Round up the punch in time minutes to the nearest 15 minutes
if [ $MINUTES -ge 0 ] && [ $MINUTES -le 7 ]
	then
		MINUTESCORRECT=00 

elif [ $MINUTES -ge 8 ] && [ $MINUTES -le 22 ]
	then
		MINUTESCORRECT=15

elif [ $MINUTES -ge 23 ] && [ $MINUTES -le 37 ]
	then
		MINUTESCORRECT=30

elif [ $MINUTES -ge 38 ] && [ $MINUTES -le 52 ]
	then
		MINUTESCORRECT=45
else
		MINUTESCORRECT="00"
		WORKHOURPLUS=1
		
fi

}

CheckIfNeg_func(){ 
INHOUR=`echo $1 | cut -d ":" -f 1`
OUTHOUR=`echo $2 | cut -d ":" -f 1`
TESTHOUR=$((OUTHOUR - INHOUR))
if [ $TESTHOUR -le -1 ]
	then
		printf "The time you entered results in a negative. Try again. \n"
	else 
		MOVEON=4
fi
}

ClockInOut_func(){
printf "\n"
while [ $MOVEON -ne 3 ]
	do
		read -p "What time did you clock in? (i.e. 14:00) <hit enter when done> " INPUT
		
		Format_func
		HourFormat_func
		MinuteFormat_func
	done
MOVEON=0
clear
printf "\n"
PUNCHIN="$INPUT"

while [ $MOVEON -ne 4 ]
	do
		read -p "Clockout time? " INPUT
		INPUTESCAPE="$INPUT"
		Format_func
		HourFormat_func
		MinuteFormat_func
		CheckIfNeg_func $PUNCHIN $INPUT
		
	done
MOVEON=0
clear
printf "\n"
PUNCHOUT="$INPUTESCAPE"

read -p "What did you do in that time? " WHATDONE
printf "\n"
clear

RoundUp_func $PUNCHIN
PUNCHINMIN="$MINUTESCORRECT"
RoundUp_func $PUNCHOUT
PUNCHOUTMIN="$MINUTESCORRECT"

PUNCHINHOUR=`echo $PUNCHIN | cut -d ":" -f 1`
PUNCHOUTHOUR=`echo $PUNCHOUT | cut -d ":" -f 1`

PUNCHINTIME=`echo "$PUNCHINHOUR"":""$PUNCHINMIN"`
PUNCHOUTTIME=`echo "$PUNCHOUTHOUR"":""$PUNCHOUTMIN"`
WORKHOUR=$((PUNCHOUTHOUR - PUNCHINHOUR))
WORKMIN=$((PUNCHOUTMIN - PUNCHINMIN))

#Sometimes you get a negative number when calculating the punch in and out minutes.
#This interprets those negative numbers 
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

if [[ $WORKHOURPLUS -eq 1 ]]
	then
		((WORKHOUR++))
fi

#format, print, redirect and email!
FINALWORKHOURS=`echo "$WORKHOUR"":""$WORKMIN"`

OUTPUT="$NAME|$TODAY|"$PUNCHINTIME"|$TODAY|$PUNCHOUTTIME|$FINALWORKHOURS|$PAYCODE|$BILLABLE|$EMERGENCY|$WHATDONE"
}
######end of clockin/out function

EmailTotal_func(){
TOTALHOURS=`expr $1 + $2`
TOTALMINS=`expr $3 + $4`
if [[ $TOTALMINS -gt 45 ]]
	then
		case $TOTALMINS in
				60)
					((TOTALHOURS++))	;;
				75)
					((TOTALHOURS++))
					TOTALMINS=15			;;
				90)
					((TOTALHOURS++))
					TOTALMINS=30			;;
				115)
					((TOTALHOURS++))
					TOTALMINS=45			;;
				*)									;;
esac
fi
EMAILTOTAL=`echo "$TOTALHOURS"":""$TOTALMINS"`
}
##################################################################
##################################################################
############## MAIN() Code #######################################
##################################################################
##################################################################

########## All time cards will be saved in this directory, so make sure its there first ############
test -d ~/Clock_Out
if [ "$?" = "1" ]
	then
		mkdir ~/Clock_Out
fi

# Hardcoded variables for expediency
TODAY=`date --rfc-3339=ns | cut -d " " -f 1`
PAYCODE="MGHPCC/INTERN"
EMERGENCY="Y"
BILLABLE="N"
NAME="mludwig"
clear
printf "\n"
echo -e "\e[1m\e[32mMGHPCC Intern Time Clock for MLudwig w\\ email return\e[0m" 
printf "\n"

read -p "Did you leave for lunch today? (Y/N) " LUNCH
while [ "$LUNCH" != "Y" ] && [ "$LUNCH" != "N" ] 2>/dev/null
	do
		read -p "Please enter \"Y\" for \"yes\" or \"N\" for \"no\"  " LUNCH
done
clear

if [ "$LUNCH" = "Y" ]
	then
		printf "\nStart with your hours before lunch.\n" 
		ClockInOut_func
		EMAILINHOUR="$WORKHOUR"
		EMAILINMIN="$WORKMIN"
		BEFORELUNCH="$OUTPUT"
		clear
		printf "Now enter your hours for after lunch.\n\n"
		printf "You left for lunch at: $PUNCHOUT\n"
		PUNCHINTEST=`echo $PUNCHOUT | cut -d ":" -f 1`
		LEFTFORLUNCH="$PUNCHOUT"
		ClockInOut_func
		EMAILOUTHOUR="$WORKHOUR"
		EMAILOUTMIN="$WORKMIN"
		while [ $PUNCHINHOUR -lt $PUNCHINTEST ]
			do
				printf "You couldn't have arrived back before you left. Try again."
				printf "You left for lunch at $LEFTFORLUNCH" 
				ClockInOut_func
		done
		PUNCHOUTHOUR="$WORKHOUR"
		PUNCHOUTMIN="$WORKMIN"
		AFTERLUNCH="$OUTPUT"
		EmailTotal_func $EMAILOUTHOUR $EMAILINHOUR $EMAILOUTMIN $EMAILINMIN
		clear
		printf "Great! Here are the formatted hours:"
		printf "\n\n"
		printf "$BEFORELUNCH\n$AFTERLUNCH\n\nThese have been emailed to mludwig@techsquare.com for easy access!"
		printf "$BEFORELUNCH\n$AFTERLUNCH" | mail -s "Hours for Morgan, $TODAY TOTAL: $EMAILTOTAL" mludwig@techsquare.com 
		printf "$BEFORELUNCH\n$AFTERLUNCH" > ~/Clock_Out/"${TODAY}.txt"

elif [ "$LUNCH" = "N" ]
	then
		ClockInOut_func
		TODAYSWORK="$OUTPUT"
		printf "Great! Here are the formatted hours:"
		printf "\n"
		printf "$TODAYSWORK\n\nThese have been emailed to mludwig@techsquare.com for easy access!"
		printf "$TODAYSWORK" | mail -s "Hours for Morgan, $TODAY TOTAL:$FINALWORKHOURS" mludwig@techsquare.com 
		printf "$TODAYSWORK" > ~/Clock_Out/"${TODAY}.txt"

fi
printf "\n"
printf "\n"
echo -e "\e[1m\e[32mGreat job today!!\e[0m"
