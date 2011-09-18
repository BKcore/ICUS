#!/bin/bash

# Copyright 2010 The ICUS Project. All rights reserved.
# This file is under the BSD License, refer to license.txt for details

# Replace "#> /dev/null" by "> /dev/null" for quiet output on 3rd party softwares (like apt-get)

################################################################################
#
# VARIABLES
#
################################################################################

ignoreSoftwares=0
ignoreConfigurations=0
overwrite=0

ICUS_HEADER="#### Welcome on ICUS ! ####\n"
ICUS_FILE=""
ICUS_FOLDER=""
CONF_FILE="icus.conf"

GLOBAL_SOFTWARES=""
GLOBAL_CONFIGURATIONS=""

################################################################################
#
# CONFIGURATION READ/WRITE/COPY FUNCTIONS
#
################################################################################


# @function conf_get
# @param1	file : the file to read
# @param2 	section : the configuration section to read
# @note		open the configuration file to see what a section looks like
function conf_get()
{
	if [ -f "$1" ] && [ -n "$2" ]
	then
		# uses awk to get lines block between BEGIN_section and END_section including those lines
		# uses sed to remove empty lines
		# uses grep to remove section delimiters
		echo `awk "/BEGIN_$2/,/END_$2/" $1 | sed /^$/d | grep -v "BEGIN_$2" | grep -v "END_$2"`
	else
		return 1
	fi
}

# @function conf_set
# desc		write a section to a conf file (type BEGIN_section ... END_SECTION)
# @param1	file : the file to write
# @param2	section : the configuration section to write
# @param3	content : the content of the section
# @note		open the configuration file to see what a section looks like
function conf_set()
{
	if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
	then
		# write into provided file the content of the provided section
		echo "BEGIN_$2" >> $1 # BEGIN_section as opening delimiter
		echo "$3" >> $1
		echo "END_$2" >> $1 # END_section as closing delimiter
		return 0
	else
		return 1
	fi
}

# @function conf_copy_backup
# @desc		save a specified software configuration into a configuration file 
# @param1	section : icus.conf section to process
function conf_copy_backup()
{
	local line

	if [ -n "$1" ]
	then 
	
		# taking each line of the chosen section in the icus.conf file
		for line in `conf_get $CONF_FILE "$1"`
		do
			#echo "$tmp_conf"
			line=${line//\~\//$HOME\/} # Workaround for cp bug with ~/ folders
			# copy the configuration file in ICUS_FOLDER with args a(archive,preserve) f(force) R(recursive)
			cp -afR $line $ICUS_FOLDER
		done
		echo "$line backed up into $ICUS_FOLDER"
	else
		return 1
	fi
}

# @function conf_copy_restore
# @desc		restore a specified configuration thanks to a previous configuration file 
# @param1	section : testing if a section is empty
function conf_copy_restore()
{
	local line
	local filename

	if [ -n "$1" ]
	then 
	
		# taking each line of the chosen section
		for line in `conf_get $CONF_FILE "$1"`
		do
			line=${line//\~\//$HOME\/} # Workaround for cp bug with ~/ folders
			
			# filename=${line##*/}
			filename=`basename "$line"`
			# echo "$filename"
			
			# make a backup of current conf file
			if [ -e $line ]
			then
				cp -afR $line "$line.old"
			fi
			
			# copy backup from $ICUS_FOLDER to original config folder
			cp -fR "$ICUS_FOLDER/$filename" $line
			echo "$filename restored into $line"
		done

	else
		return 1
	fi
}

# @function conf_file_exists
# @desc 	tests if a configuration file icus.conf exists or not
# @param1	icus.conf file
# @param2	the configuration section to read
function conf_file_exists()
{
	local tmpConfFile

	for tmpConfFile in $(conf_get $CONF_FILE $1) # foreach configuration file in icus.conf
	do
		tmpConfFile=${tmpConfFile//\~\//$HOME\/}
		if !([ -e $tmpConfFile ]) # test if the file exists
		then
			return 1
		fi
	done
	
	return 0
}

################################################################################
#
# ACTION FUNCTIONS
#
################################################################################

# @function	action_save_file
# @desc		save settings into the .save file and configuration files into the ICUS_FOLDER
function action_save_file()
{
	local overwrite
	local ignoreSoftwares
	local ignoreConfigurations
	local conf

	clear

	# check if file is provided
	# this case should never be triggered since it's being tested in the main part
	if [ -z $ICUS_FILE ]
	then
		echo "Unexpected error"
		echo "Unable to create automatic filename" # see main part of the script
	fi

	# check previous file existance
	echo "ICUS will save your settings into \"$ICUS_FILE\""
	if [ -f $ICUS_FILE ]
	then
		echo "The file already exists and thus will be overwritten"
		read -p "Proceed nevertheless ? (y/n) : " overwrite
		if [ "$overwrite" = "y" ]
		then
			# clean file content
			echo "" > $ICUS_FILE
		else
			echo "Press enter to go back to previous menu"
			read /dev/null
			menu_sub1
		fi
	fi
	
	# same with the folder
	echo "ICUS will backup your conf files into \"$ICUS_FOLDER\""
	if [ -d $ICUS_FOLDER ]
	then
		echo "The folder already exists"
		read -p "Do you want ICUS to back it up as \"$ICUS_FOLDER.old\" and proceed ? (y/n) : " overwrite
		if [ "$overwrite" = "y" ]
		then
			# backup folder as foldername.old
			rm -r "$ICUS_FOLDER.old"
			mv $ICUS_FOLDER "$ICUS_FOLDER.old"
			echo "Backup created as $ICUS_FOLDER.old, Proceeding..."
		else
			echo "Press enter to go back to previous menu"
			read /dev/null
			menu_sub1
		fi
	fi

	# parse software list
	if [ -d "$GLOBAL_SOFTWARES" ]
	then
		echo "No software selected"
		read -p "Proceed nevertheless ? (y/n) : " ignoreSoftwares
		if [ "$ignoreSoftwares" = "y" ]
		then
			ignoreSoftwares=1 # ability to bypass software save
		else
			ignoreSoftwares=0
		fi
	else
		ignoreSoftwares=0
	fi
	
	# parse configuration list
	if [ -z "$GLOBAL_CONFIGURATIONS" ]
	then
		if [ -z "$GLOBAL_SOFTWARES" ] # forbid writing if no software and no conf selected
		then
			echo "Trying to write savefile with no software and no configuration selected"
			echo "Press enter to go back to the menu"
			read /dev/null
			menu_sub1
		fi
		
		echo "No configuration selected"
		read -p "Proceed nevertheless ? (y/n) : " ignoreConfigurations
		if [ "$ignoreConfigurations" = "y" ]
		then
			ignoreConfigurations=1 # ability to bypass configurations save
		else
			ignoreConfigurations=0
		fi
	else
		ignoreConfigurations=0
	fi
		
		
	# save softwares list to savefile
	if [ $ignoreSoftwares -eq 0 ]
	then
		conf_set $ICUS_FILE "softwares" "$GLOBAL_SOFTWARES" # write softwares section into savefile
		echo ""
		echo "Softwares saved :"
		echo $GLOBAL_SOFTWARES
	fi
		
	# save configuration to file and backup corresponding savefiles
	if [ $ignoreConfigurations -eq 0 ]
	then
		echo ""
		echo "Backing up your conf files..."
		echo "This may take some time depending on the amount of files to copy"
		echo ""
		mkdir $ICUS_FOLDER
		conf_set $ICUS_FILE "configurations" "$GLOBAL_CONFIGURATIONS" # write configurations section into savefile
		for conf in $GLOBAL_CONFIGURATIONS # foreach file to backup
		do
			conf_copy_backup $conf # copy the conf file into the savefiles' directory
		done
		
		echo "Your configuration files were successfuly stored into \"$ICUS_FOLDER\""
	fi
	
	echo "Your settings were successfuly saved into \"$ICUS_FILE\""
	echo ""
	echo "Thank you for using this software brought to you by"
	echo "Benjamin GUILLET <benjamin.guillet@utbm.fr>"
	echo "Thibaut DESPOULAIN <thibaut.despoulain@utbm.fr>"
	echo "Thomas REAL <thomas.real@utbm.fr>"
	exit 0
}

# @function	action_choose_softwares
# @desc		add the complete softwares list to .save file to backup
function action_choose_softwares()
{
	local softwares=""
	local choiceSoft="0"
	local override
	
	clear
	
	echo "Type a software name and press enter between each software"
	echo "Type \"L\" or \"l\" and enter to print what you've provided so far"
	echo "Type \"Q\" or \"q\" and enter when you're done adding softwares"
	echo ""
	
	while ([ "$choiceSoft" != "q" ] && [ "$choiceSoft" != "Q" ]) || [ "$choiceSoft" = "" ] # while we're not entering 'Q' or 'q' to quit, do
	do
		read -p " > " choiceSoft
		choiceSoft=${choiceSoft//\ /_} # prevents spaces in soft name (replace with _)
		if [ -z $choiceSoft ]
		then
			echo "Empty. Use Q to quit"
		elif [ $choiceSoft = "q" ] || [ $choiceSoft = "Q" ]
		then # quit
			echo "Done"
		elif [ $choiceSoft = "l" ] || [ $choiceSoft = "L" ]
		then # show selected packages
			echo "Currently selected packages : $softwares"
		else
			if apt-cache pkgnames | grep -x -q $choiceSoft
			then # check if package exists in apt-cache
				softwares="$softwares $choiceSoft"
				echo "$choiceSoft added"
			else
				echo "$choiceSoft not found in apt-cache"
				read -p "Do you still want to add it ? (y/n) : " override
				if [ $override = "y" ]
				then # force software add
					softwares="$softwares $choiceSoft"
					echo "$choiceSoft added"
				fi
			fi
		fi
	done
	
	# format $softwares for file writing
	softwares=`echo $softwares | tr " " "\n"`
	
	# return $(conf_set $ICUS_FILE 'softwares' $softwares)
	GLOBAL_SOFTWARES=$softwares
	
	# Back to previous menu
	menu_sub1
}

# @function	action_choose_configurations
# @desc		add the complete configurations list to .save file
function action_choose_configurations()
{
	local configurations=""
	local choiceConf="0"
	local conflist=`grep "BEGIN_" $CONF_FILE | tr -d "BEGIN_" | sort`
	local addAllConfig
	local tmpChoiceConf
	
	clear
	
	echo "Type a configuration name and press enter between each input"
	echo "Type \"A\" or \"a\" and enter to add all available configurations at once"
	echo "Type \"L\" or \"l\" and enter to print what you've provided so far"
	echo "Type \"S\" or \"s\" and enter to show known configurations"
	echo "Type \"Q\" or \"q\" and enter when you're done adding configurations"
	echo ""
	echo "ICUS-known configurations (icus.conf) :"
	echo $conflist
	echo ""
	
	while ([ "$choiceConf" != "q" ] && [ "$choiceConf" != "Q" ]) || [ "$choiceConf" = "" ]
	do
		read -p " > " choiceConf
		choiceConf=${choiceConf//\ /_} # prevents spaces in conf name (replace with _)
		if [ -z $choiceConf ]
		then
			echo "Empty. Use Q to quit"
		elif [ $choiceConf = "q" ] || [ $choiceConf = "Q" ]
		then
			echo "Done"
		elif [ $choiceConf = "l" ] || [ $choiceConf = "L" ]
		then
			echo "Currently selected configurations : $configurations"
		elif [ $choiceConf = "s" ] || [ $choiceConf = "S" ]
		then
			echo "Known configurations :"
			echo $conflist
		elif [ $choiceConf = "a" ] || [ $choiceConf = "A" ]
		then
			echo "This will add the complete configuration list to the save file"
			read -p "Proceed ? (y/n) : " addAllConfig
			if [ "$addAllConfig" = "y" ]
			then
				configurations=""
				for tmpChoiceConf in $conflist
				do
					if conf_file_exists $tmpChoiceConf
					then
						configurations="$configurations $tmpChoiceConf"
						echo "$tmpChoiceConf added"
					else
						echo "Could not find any $tmpChoiceConf configuration file"
					fi
				done
			fi
		else
			if echo "$conflist" | grep $choiceConf > /dev/null # testing if it's a known configuration
			then
				if conf_file_exists $choiceConf
				then
					configurations="$configurations $choiceConf"
					echo "$choiceConf added"
				else
					echo "Could not find any $choiceConf configuration file"
					echo "Please check if the configuration exists in your computer"
				fi
			else
				echo "ICUS doesn't know how to handle $choiceConf configuration"
				echo "Known configurations are stored in $CONF_FILE"
				echo "Type \"S\" or \"s\" and enter to show known configurations"
			fi
		fi
	done
	
	# format $configurations for file writing
	configurations=`echo $configurations | tr " " "\n"`
	
	# return $(conf_set $ICUS_FILE 'configurations' $configurations)
	GLOBAL_CONFIGURATIONS=$configurations
	
	# Back to previous menu
	menu_sub1
}

## RESTORATION FUNCTIONS ##

# @function	action_check_savefile_integrity
# @desc		check if the .save file contains softwares and configurations
# @param	Parameter : *.save file 
function action_check_savefile_integrity()
{
	local ignoreSoftwares
	local ignoreConfigurations

	echo "Checking savefile integrity..."
	
	if !([ -r $ICUS_FILE ]) # check if file exists and is readable 
	then
		echo "Unable to read \"$ICUS_FILE\" save file"
		echo "Make sure \"$ICUS_FILE\" exists and as read rights"
		exit 1
	fi

	if [ -z `grep BEGIN_softwares $ICUS_FILE` ] || [ -z "`conf_get $ICUS_FILE 'softwares'`" ]  # check if savefile contains softwares section
	then
		echo "Savefile does not contain any software save"
		read -p "Continue restoration nevertheless ? (y/n) : " ignoreSoftwares
		if [ "$ignoreSoftwares" = "y" ]
		then
			ignoreSoftwares=1 # ability to bypass software restoration
			echo "Proceed checking savefile integrity..."
		else
			echo "Exiting..."
			exit 1
		fi
	fi
	
	if [ -z `grep BEGIN_configuration $ICUS_FILE` ] || [ -z "`conf_get $ICUS_FILE 'configurations'`" ] # check if savefile contains configuration section
	then
		echo "Savefile does not contain any configuration save"
		read -p "Continue restoration nevertheless ? (y/n) : " ignoreConfigurations
		if [ "$ignoreConfigurations" = "y" ]
		then
			ignoreConfigurations=1 # ability to bypass configuration restoration
			echo "Proceed checking savefile integrity..."
		else
			echo "Exiting..."
			exit 1
		fi
	fi
	
	if [ "$ignoreConfigurations" = "1" ] && [ "$ignoreSoftwares" = "1" ]
	then
		echo "ICUS being lazy, it doesn't like to run for nothing"
		echo "Your save file doesn't contain any software or configuration saved"
		echo "Please run \"./icus.sh -c\" to create a valid save file"
		echo "Exiting..."
		exit 1
	fi
	

	return 0
}

# @function action_test_networK
# @desc		restore the network configuration and ping to check if the user is now connected to the internet
# @param	*.save file 	
function action_test_network()
{
	local test=$(conf_get $ICUS_FILE "configurations")
	local restoreNetwork
	
	if [ -n "`echo "$test" | grep network`" ]
	then
		echo "ICUS found a network configuration in $ICUS_FILE"
		read -p "Do you want to restore it before testing the internet connection ? (y/n) : " restoreNetwork
		if [ "$restoreNetwork" = "y" ]
		then
			echo "Restoring network configuration..."
			conf_copy_restore "network"
		fi
	fi
		
	#test if a network configuration is present in icus.save
	#if !(echo $test | grep network > /dev/null)
	#then
	echo "Testing your internet connection..."
		if ping -c 1 www.google.com > /dev/null
		then
			echo "Internet connection found, Proceeding..."
		else
			echo -e "\nNo internet connection available"
			echo "You have to be connected to the internet in order to use ICUS restore function"
			echo "Exiting..."
			menu_root
		fi
	#fi
}

# @function	action_restore_update
# @desc		restore the configurations specified in .save file
# @param	*.save file
function action_restore_update()
{
	
	#TODO: restore sources.list before updating (have to handle versions)
	
	echo "Updating your system..."
	echo "This could take a few minutes depending on your internet connection..."
	apt-get -y update #> /dev/null
	apt-get -y upgrade #> /dev/null
	echo "System updated"
	echo ""
	
	return 0
}

# @function	action_restore_software
# @desc 	restore the softwares specificed in .save file running apt-get to install back softwares
# @param 	*.save file
function action_restore_software()
{
	local softwaresToRemove=""
	local choiceSoft
	
	echo "Restoring softwares specified in $ICUS_FILE"
	echo "This could take a few minutes depending on your internet connection..."
	
	for choiceSoft in $(conf_get "$ICUS_FILE" "softwares")
	do
		if apt-cache pkgnames | grep -x -q $choiceSoft # check if package exists in apt-cache
		then
			apt-get -y install $choiceSoft #> /dev/null
			echo "$choiceSoft installed"
		else
			echo "$choiceSoft not found in apt-cache"
		
			softwaresToRemove="$softwaresToRemove $choiceSoft"
		fi
	done
	
	if [ -n "$softwaresToRemove" ]
	then
		echo "The following packages could not be found in repositories, and thus were not installed :"
		echo $softwaresToRemove
	fi
		
	return 0
}

function action_restore_configuration()
{
	local confToRestore

	echo -e "\nRestoring configurations specified in $ICUS_FILE"
	echo "Your actual configurations will be backed up as FILE.old"
	echo "This could take a few minutes depending on the amount of configurations"
	
	for confToRestore in $(conf_get "$ICUS_FILE" "configurations")
	do
		conf_copy_restore $confToRestore
	done
	
	return 0
}

# @function	action_restore
# @desc		call all actions_restore functions
# @param	*.save file
function action_restore()
{
	local testSoft
	local testConf

	action_check_savefile_integrity
	action_test_network
	action_restore_update
	
	testSoft=$(conf_get "$ICUS_FILE" "softwares")
	if [ -n "$testSoft" ]
	then
		action_restore_software
	else
		echo "There is no software to restore"
	fi
	
	testConf=$(conf_get "$ICUS_FILE" "configurations")
	if [ -n "$testConf" ]
	then
		action_restore_configuration
	else
		echo "There is no configuration to restore"
	fi
	
	echo -e "\nICUS is now finished restoring \"$ICUS_FILE\""
	echo ""
	echo "Thank you for using this software brought to you by"
	echo "Benjamin GUILLET <benjamin.guillet@utbm.fr>"
	echo "Thibaut DESPOULAIN <thibaut.despoulain@utbm.fr>"
	echo "Thomas REAL <thomas.real@utbm.fr>"
}
################################################################################
#
# MENU FUNCTIONS
#
################################################################################

# Main menu

# @function	menu_root
# @desc 	print the main menu
function menu_root()
{	
	local choice="-1"

	while [ -z $choice ] ||[ $choice != "0" -a $choice != "1" -a $choice != "2" ]
	do
		clear
	
		echo -e $ICUS_HEADER
	
		echo -e "- Main menu\n"
	
		echo "0) Exit"
		echo "1) Create a save file"
		echo -e "2) Restore system\n"
	
		read -p " > " choice

		case $choice in
			"0")
				echo 'Exiting...'
				exit 0
				;;
		
			"1")
				menu_sub1
				;;
	
			"2")
				menu_sub2
				;;
				
			*)
				echo -e "Please enter a number between 0 and 2\n"
				;;
		esac
	done

	return 0
}


# Submenu 1

# @function	menu_sub1
# @desc		print the creation of save file menu
function menu_sub1()
{
	local choiceSave="-1"	
	
	while [ -z $choiceSave ] || [ $choiceSave != "0" -a $choiceSave != "1" -a $choiceSave != "2" -a $choiceSave != "3" ]
	do
		clear

		echo -e $ICUS_HEADER
		echo -e "- ICUS configuration maker ($ICUS_FILE)\n"
		echo "Currently selected softwares : `echo "$GLOBAL_SOFTWARES" | sort | tr "\n" " "`"
		echo ""
		echo "Currently selected configurations : `echo "$GLOBAL_CONFIGURATIONS" | sort | tr "\n" " "`"
		echo ""
		echo "0) Back to main menu"
		echo  "1) Choose saved softwares"
		echo  "2) Choose saved configurations"
		echo -e "3) Save to file and go back to main menu\n"	

		read -p " > " choiceSave

		case $choiceSave in
		
		"0")
			menu_root
			;;
					
		"1")
			clear
			echo -e $ICUS_HEADER
			action_choose_softwares
			;;
		"2")
			clear
			echo -e $ICUS_HEADER
			#YOU HAD A ISSUE WITH THE PREVIOUS SYSTEM WHILE DOING THE CONFIGURATION THIS ISSUE MIGHT BE RESTORED TOO
			action_choose_configurations
			;;
			
		"3")
			echo -e $ICUS_HEADER
			action_save_file
			;;	
			
		*)
			echo -e "Please enter a digit between 0 and 3\n"
			;;
		esac
	done
	
	return 0
}

# Submenu 2

# @function	menu_sub2
# @desc		print the restoration of save file menu
function menu_sub2()
{
	local choiceRestore
	
	clear

	if [[ $EUID -ne 0 ]]; then
		echo "The ICUS restoration must be run as root"
		echo "Usage: sudo ./icus.sh -r file.save"
		exit 1
	fi

	echo -e "- ICUS restoration\n"	
	echo "THIS ACTION WILL RESTORE ALL YOUR PREVIOUS APPLICATIONS AND CONFIGURATIONS"
	echo "The configuration file specified is $ICUS_FILE"
	read -p "Do you still want to continue ? (y/n) : " choiceRestore
	
	if [ $choiceRestore = "y" ]
	then
		action_restore
	else
		menu_root
	fi
	
	return 0
}

################################################################################
#
# MAIN
#
################################################################################

case $1 in
	"-c" | "--configure")

		if [ -z $2 ]
		then
			ICUS_FILE="icus_`date +%Y-%m-%d`.save"
			ICUS_FOLDER="${ICUS_FILE%.*}"
		else
			ICUS_FILE=$2
			ICUS_FOLDER="${ICUS_FILE%.*}"
		fi
	
		menu_sub1
		;;
	
	"-r" | "--restore")

		if [ -f $2 ]
		then
			ICUS_FILE=$2
			ICUS_FOLDER="${ICUS_FILE%.*}"
		else
			echo "You need to provide a valid save file to use ICUS restore function"
			echo "Usage: sudo ./icus.sh -r file.save"
			exit 1
		fi
	
		menu_sub2
		;;
	"--help")

		echo -e $ICUS_HEADER
		echo "DESCRIPTION"
		echo "ICUS is a script that helps you save and restore configurations, softwares, internet profiles..."
		echo "ICUS generates a ICUS_date.save file to restore later the previous configuration (After a system reinstall for example)"
		echo ""
		echo "USAGE"
		echo "   icus.sh [OPTION] [FILE]"
		echo ""
		echo "OPTIONS"
		echo "   -c, --configure       direct access to the configuration menu"
		echo "   -r, --restore         direct access to the restore menu"
		echo "   --help                display this help"
		echo "FILE"
		echo "   *.save                the configuration file"
		echo ""
		echo "AUTHORS"
		echo "Benjamin GUILLET <benjamin.guillet@utbm.fr>"
		echo "Thibaut DESPOULAIN <thibaut.despoulain@utbm.fr>"
		echo "Thomas REAL <thomas.real@utbm.fr>"
		echo ""
		exit 0;
		;;
	*)
		if [ -z $1 ]
		then	
			ICUS_FILE="icus_`date +%Y-%m-%d`.save"
			ICUS_FOLDER="${ICUS_FILE%.*}"
			menu_root
		
		elif [ -f $1 ] 
		then
			ICUS_FILE=$1
			ICUS_FOLDER="${ICUS_FILE%.*}"
			menu_root
		else
			echo "Invalid argument"
		fi

		;;
esac

echo "Exiting ICUS..."
exit 0
