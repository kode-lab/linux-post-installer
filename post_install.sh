#!/bin/bash
########################################
# [public] Linux Post Install Script   #
# by Kyle Ketchell                     #
########################################

# How to use this script:
# Copy it to your home directory then open a new terminal window and run:
# $ chmod u+x post_install.sh
# then, run the script as root:
# $ sudo ./post_install.sh

# Things you may want to change
temp_password="password1234"							#the temporary password for new users.
s_drive_path="//some.drive.com/path"					#the path to a network drive containing software, scripts, or other configuration things
default_shell="/bin/bash"								#the default shell for new users (/bin/bash is a good one, so is /bin/zsh)

# Things you really shouldn't change without a backup
filename=`hostname`"_"`date +"%Y-%m-%d_%H_%M_%S"`".log"			#the name of the logfile. it will look like hostname_2022-04-05_12_15_32.log
lfilename=`hostname`"_"`date +"%Y-%m-%d_%H_%M_%S"`".longlog"	#the name of the longlog file. it will look like hostname_2022-04-05_12_15_32.longlog

#colors! use it like : echo -e "$GREEN some_green_text $RESET some_plain_text"
GREEN='\033[0;32m'				#ANSI escape code for Green
RED='\033[0;31m'				#ANSI escape code for Red
WHITE='\033[0;37m'				#ANSI escape code for White
BLUE='\033[0;34m'				#ANSI escape code for Blue
TEAL='\033[0;100m\033[0;36m'	#ANSI escape code for Teal
RESET='\033[0m'					#ANSI escape code for nothing/reset


# Things you shouldn't change unless you really know what you're doing (i.e. the rest of the script)

#======== test for execution as root ==============
check_root() {
  if [ "$EUID" -ne 0 ]; then													#if your uid is not 0 then you're not root
    echo -e "${RED}You can't run this script! You need to execute it as root."	#complain that this can't run if you're not root
    echo -e "${TEAL}run: ${RESET}sudo ./post-install.sh${RESET}"				#tell the user to use sudo
    exit																		#exit
  fi																			#otherwise you're fine, move on
  ####################################################################################################################
  # Documentation: This script needs to be run as root in order to work. Creating users, updating programs, etc      #
  # all require root privelages to work. If you're not root, this detects that, complains, and exits                 #
  # However, this script also requires a non-root user to exist who will be the 'admin' of the comptuer [internally, #
  # this is strictly necessary but you may not need this]                                                            #
  ####################################################################################################################
}


#======== begin logfiles ==========================
begin_logs() {
  echo ${filename} >> ${filename}						#write the name of the file to the top of the .log file
  echo ${lfilename} >> ${lfilename}						#write the name of the file to the top of the .longlog file		
  cat /etc/*-release &>> ${lfilename}					#tell me about this installation via the /etc/*-release file and put it in the longlog file
  echo "eof: **** /etc/*-release ****" >> ${lfilename}	#formatting for the longlog file
  echo "" >> $filename									#formatting
  echo "" >> $lfilename									#formatting
  ####################################################################################################################
  # Documentation: There are 2 logfiles created by this script, *.log and *.longlog.                                 #
  # *.log contains things like the date/time of install, users added, and their password                             #
  # *.longlog contains things like the output of apt install and drive mapping things (its much very way way long)   #
  # after the script is run, these files are copied to S:\ENS\ISO\Linux Post Install Script\.logs                    #
  # you can find the computer name and install time in the file name, then see what happened when the script was run #
  ####################################################################################################################
}


#========= Begin Script ===================
begin_script() {
  echo "************** Begin Script **************" >> $filename							#formatting for log files
  echo "************** Begin Script **************" >> $lfilename							#formatting for log files

  echo -e "${GREEN}First things first. Who is the non-root administrator of this computer?$RESET"	#Who is the non-root admin of the computer? Prompt the user to enter the username
  read current_username																		#get user input

  echo "executing as ${current_username}"		#tell the user who they are

  echo "Username: ${current_username}" >> ${filename}				#tell the log file who the user was
  echo "Username: ${current_username}" >> ${lfilename}				#tell the longlog file who the user was

  ####################################################################################################################
  # Documentation: $current_username should be the non-root username of the user performing the install. [this is    #
  # more important in an internal implementation of this script where the non-root user is an IT administrator]      #
  ####################################################################################################################
  echo "" >> $filename							#add a space to make log file more readable
  echo "" >> $lfilename							#add a space to make longlog file more readable
}


#========= SOFTWARE DRIVE ===================
map_software_drive() {
  #[this is important for an internal implementation of this script which requires access to this network drive]
  echo "************** SOFTWARE DRIVE **************" >> $filename
  echo "************** SOFTWARE DRIVE **************" >> $lfilename

  apt install cifs-utils -y &>>${lfilename} 		#the software drive needs cifs-utils in order to be mapped, this needs to be installed now.

  echo -e "${BLUE}Mounting Software Drive.$RESET"	#tell the user we're going to the software drive

  if [ ! -d "SOFTWARE" ]; then						#If there isn't a directory called SOFTWARE, make one
    mkdir SOFTWARE									#make a directory called SOFTWARE
    echo "Created `pwd`/SOFTWARE" >> ${filename}	#log it
  fi	

  #actually map the software drive according to the directions on the website. Note that you shouldn't use 'sudo' here, because the script should be run as root anyway. sudo doesn't work in scripts.
  ##[your command to map a network drive goes here]

  if [ ! -d "SOFTWARE/[INTERNAL]" ]; then												# check to see if the drive was mounted, if so, the directory SOFTWARE/[INTERNAL] exists. If not, then:
    echo -e "${RED}UNABLE TO MAP SOFTWARE DRIVE. SEE .LOG FOR MORE DETAILS${RESET}"		# complain to the user
    echo "Unable to map Software drive." >> $filename									# log the failure to the logfile
	echo -e "${RED}This script will have problems without the S:\ drive.${RESET}"		# tell the user that this is actually a big deal
	echo -e "${GREEN}Do you wish to continue? (y/n):$RESET"								# ask the user if they understand and want to continue
	read continue																		# get user input
	if [[ $continue == "n" ]]; then														# if the user doesnt want to contiue:
	  echo "Exiting. Please make sure the S:\ drive gets mounted!"						# complain
	  exit																				# quit
	fi
  else																					# otherwise, nothing went wrong
    echo "Mounted [Network Drive Location] to "`pwd`"/SOFTWARE"							# tell the user all is good
    echo "Mounted [Network Drive Location] to "`pwd`"/SOFTWARE" >> ${filename}			# log it
	echo "Mounted [Network Drive Location] to "`pwd`"/SOFTWARE" >> ${lfilename}			# log it
  fi
  
  ####################################################################################################################
  # Documentation: this chunk here maps the S:\ drive. its important, especially if you want to install matlab later.#
  # it will also copy a few files from the S:\ drive and copy the .log files to the S:\ drive.                       #
  ####################################################################################################################
  
  echo "" >> $filename
  echo "" >> $lfilename
}


#========= Adding users ===================
change_default_password() { #(you don't normally need this - see documentation)
  echo "************** Changing Default Password (custom password) **************" >> $filename		#tell the log file we're changing the password 
  echo "************** Changing Default Password (custom password) **************" >> $lfilename	#tell the longlog file we're changing the password

  while :																							# loop to get a password
  do
  echo -e "${GREEN}What should the default password be? ($temp_password):$RESET" 					#ask, What should the default password be?
  read password1																					#get input from user
  echo -e "Retype password:"																		#prompt user to verify password
  read password2																					#get input from user
  if [[ $password1 == $password2 ]]; then															#if the passwords match then that password will be used
    echo "password: $password1" >> ${filename}														#write the used password to the logfile
    break																							#move on
  fi																								#if the passwords didnt match then get user input again
  done
  
  temp_password=$password1

  #We know what the password will be. Tell that to the user, and move on
  echo -e "Ok. Password will be ${RED}$password${RESET}."

  ####################################################################################################################
  # Documentation: Maybe there's some reason you don't want to use the default option as the password. This function #
  # changes the default password during runtime for you. If you want the ability to change the default password,     #
  # uncomment the line change_default_password() below (remove the # character at the beginning)                     #
  # otherwise, leave that line commented out (leave the # at the beginning)                                          #
  ####################################################################################################################
  
  echo "" >> $filename	#add a space to make logfile more readable
  echo "" >> $lfilename	#add a space to make logfile more readable
}


add_users() {
  echo "************** Adding users **************" >> $filename				#tell the log file we're adding users
  echo "************** Adding users **************" >> $lfilename				#tell the longlog file we're adding users
  echo -e "${BLUE}Adding users.${RESET}"										#write to display, tell the user we're adding users
  password=$temp_password														#this section uses the variable password, so get the temp_password and use it
  
  #We know what the password will be. Tell that to the user, and prompt them to start adding super users
  echo -e "Password will be ${BLUE}$password${RESET}. Add users, enter 'qq' as the last user."
  echo -e "Adding ${RED}sudo users${RESET} first. Only enter usernames that will have admin privelages."

  while (true)																	#A loop to add super users
  do
    echo -e "${GREEN}Enter Username (qq when done): $RESET"						#Prompt (to display) for the user to enter a username)
    read username																#get input from user 
    if [ $username != "qq" ]													#--if the input is not qq
    then																		#--then this is a real username, add the user
      useradd -m -G sudo $username &>> $lfilename								#create user and add user to group sudo
      echo -e "$password\n$password" | passwd $username &>> $lfilename			#change password
      echo $default_shell | sudo chsh $username &>> $lfilename					#change shell to default_shell (/bin/bash)
      adduser $username ssl-cert &>> $lfilename									#add user to the ssl-cert group (so they can use xrdp)
      passwd --expire $username &>> $lfilename									#set user password to expire (they have to change it at next login)
      echo "Created sudoer $username with password $password"					#log it to display
      echo "Created sudoer $username with password $password" >> ${filename}	#log it to log
      echo "Created sudoer $username with password $password" >> ${lfilename}	#log it to longlog
    else																		#--otherwise qq is not a real username, don't add that user, move on
      echo "Done adding sudoers" >> $filename									#log it
      echo "Done adding sudoers" >> $lfilename									#log it
      break																		#exit the loop
    fi
  done																			#No more super users to add. 

  #Moving on to regular users. 
  echo -e "Adding ${TEAL}regular (non-sudo)${RESET} users. The default password is still $BLUE${password}$RESET"
  echo "Enter usernames. Enter 'qq' to finish adding users."

  while (true)																	#A loop to add regular users
  do
    echo -e "${GREEN}Enter Username (qq when done): $RESET"						#Prompt (to display) for the user to enter a username)
    read username																#get input from user 
    if [ $username != "qq" ]													#--if the input is not qq
    then																		#--then this is a real username, add the user
      useradd -m $username	&>> $lfilename										#create user
      echo -e "$password\n$password" | passwd $username &>> $lfilename			#change password
      echo $default_shell | sudo chsh $username &>> $lfilename					#change shell to default_shell (/bin/bash)
	  adduser $username ssl-cert &>> $lfilename									#add user to the ssl-cert group (so they can use xrdp)
      passwd --expire $username &>> $lfilename									#set password to expire
      echo "Created regular user $username with password $password"				#log it to display
      echo "Created non sudoer $username with password $password" >> ${filename}	#log it to log
      echo "Created non sudoer $username with password $password" >> ${lfilename} 	#log it to longlog
    else																		#--otherwise qq is not a real username, don't add that user, move on
      echo "Done adding nonsudoers" >> $filename								#log it
      echo "Done adding nonsudoers" >> $lfilename								#log it
      break																		#exit the loop
    fi
  done
  
  ####################################################################################################################
  # Documentation: use the password provided near line 15 as the default password. Enter usernames one at a time     #
  # until you have no more users to add. enter "qq" to stop (this won't create a user named 'qq')	                 #
  ####################################################################################################################
  
  echo "" >> $filename	#add a space to make logfile more readable
  echo "" >> $lfilename	#add a space to make logfile more readable
}


#=================== Install Packages and updates ===================
install_updates() {
  echo -e "${TEAL}You're done for now. Go chug a beer (for those under 21 please drink sudo beer)$RESET"	
  #Why don't computer scientists get drunk at parties? 
  #They always drink beers with sudo! [root beers]

  echo "************** Install Packages and Updates **************" >> $filename
  echo "************** Install Packages and Updates **************" >> $lfilename

  echo "Updating and Upgrading in apt..."									#tell the user what we're doing
  apt update -y &>>${lfilename} 											#apt update (and log it)
  echo "Trust me, its working. This is just gonna take a second."
  echo "(more like 10,000 seconds, but whatever)." 							#assure the user that it works
  apt upgrade -y &>>${lfilename} 											#apt upgrade (and log it)

  ####################################################################################################################
  # Documentation: linux (stupidly) doesn't always install the latest packages during an install. This script does   #
  # that.                                                                                                            #
  ####################################################################################################################
  echo "" >> $filename
  echo "" >> $lfilename
}


#=================== Easy Software Installer (EESI) ==============
eesi() {
  echo "************** EESI **************" >> $filename
  echo "************** EESI **************" >> $lfilename
  
  extensive="y"													#yes, we will do an extensive install
  
  echo "chose ${extensive} to eesi" >> ${filename}				#log if we're doing an extensive install
  
  if [[ $extensive == "y" ]]; then
    echo "Installing Python3 and Python3-pip"									#tell the user that we're installing python
    apt install python3 python3-pip python-is-python3 -y &>>${lfilename}		#actually install python, log it
    echo "Installing vim, openssh, htop, neofetch, git"					    	#tell the user that we're installing vim
    apt install vim figlet htop neofetch git xfce4 xrdp -y	&>>${lfilename}		#actually install those programs, log it
    apt install openssh-server -y &>>${lfilename}								#install openssh-server, log it
	DEBIAN_FRONTEND=noninteractive apt install -y \								# There's something weird here where lightdm requires some
	#apt install -y \ #															# user interaction but that obviously gets piped to the log file
       	vlc openssh-server zsh fish \											# so ya don't know what to do. work in progress.
       	tightvncserver xrdp wget git build-essential \
       	cmake subversion mercurial cvs libmpich-dev \
       	geany emacs \
       	tmux remmina remmina-plugin-* \
       	bluefish gdb gedit libpthread-stubs0-dev &>>${lfilename}
  fi	#install a bunch of software using apt
  echo "Installed vlc, zsh, fish, tightvncserver, xrdp, wget, git, cmake, subversion, mercurial, cvs, emacs, geany, tmux, remmina, bluefish, gdb, and gedit"	#tell the user what we just installed
  
  ####################################################################################################################
  # Documentation: linux (stupidly) doesn't install these super helpful packages during an install. This script does #
  # that.                                                                                                            #
  ####################################################################################################################
  echo "" >> $filename
  echo "" >> $lfilename
}


#=================== setting up ssh and ufw ===================
set_up_ssh() {
  echo "************** Setting up ssh and ufw **************" >> $filename
  echo "************** Setting up ssh and ufw **************" >> $lfilename

  echo "Setting up ssh"
  systemctl enable sshd &>> $lfilename		#enable ssh (make it start working at startup)
  #ufw status 

  echo "Setting up ufw" >> ${lfilename}
  ufw enable &>> $lfilename					#turn on firewall
  ufw default allow outgoing &>> $lfilename	#allow all outgoing connections
  ufw default deny incoming &>> $lfilename	#deny all incoming connections
  ufw allow in ssh &>> $lfilename			#allow ssh incoming
  ufw allow in 3389/tcp &>> $lfilename		#allow incoming via 3389 (for remote desktop/x2go)
  ufw status &>> ${lfilename}				#check status of firewall and put in longlog

  systemctl enable ssh &>> $lfilename		#make extra sure ssh got enabled
  systemctl enable sshd &>> $lfilename		#make super extra sure ssh got enabled

  echo "done setting up ssh" >> ${lfilename}
  echo "done setting up ssh"
  ####################################################################################################################
  # Documentation: ssh allows remote access to the computer. if this is set up, then you can simply get the IP of the#
  # computer, and connect using "ssh username@ip.ip.ip.ip" or "ssh username@computername" if it's on the domain.     #
  ####################################################################################################################
  echo "" >> $filename
  echo "" >> $lfilename
}


#=================== Misc. Config ===================
misc_config() {
  echo "************** Misc. Config **************" >> $filename
  echo "************** Misc. Config **************" >> $lfilename
  echo "We have a few more things to configure..."

  #echo "[User]" > /var/lib/AccountsService/users/$current_username &>> ${lfilename}
  #echo "SystemAccount=True" >> /var/lib/AccountsService/users/$current_username &>> ${lfilename}
  #On Ubuntu, this ^ might? make it so that the user list doesnt show (work in progress)

  #---------- change default wallpaper ----
  if [ -d "/usr/share/backgrounds/linuxmint" ]; then											#if this directory exists, then we're using Linux Mint, and we should set up the backgrounds accordingly
    mv /usr/share/backgrounds/linuxmint/default_background.jpg /usr/share/backgrounds/linuxmint/default_background_old.jpg				#move the old wallpaper to a backup
    cp [PATH TO BACKGROUND] /usr/share/backgrounds/linuxmint/default_background.jpg				#copy the new wallpaper to the correct location
    echo "[SeatDefaults]" > /etc/lightdm/lightdm.conf.d/50-myconfig.conf						#Since this is linux mint, we can hide users on the login screen
    echo "greeter-hide-users=true" >> /etc/lightdm/lightdm.conf.d/50-myconfig.conf				#these 3 lines do that
    echo "greeter-show-manual-login=true" >> /etc/lightdm/lightdm.conf.d/50-myconfig.conf		#hide users
  else																							#if not, we're on ubuntu, and we should set up the backgrounds accordingly
    mv /usr/share/backgrounds/warty-final-ubuntu.png /usr/share/backgrounds/warty-final-ubuntu-old.png			#backup the old wallpaper
    mv /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfce-verticals-old.png		#backup the old wallpaer
    cp [PATH TO BACKGROUND] /usr/share/backgrounds/warty-final-ubuntu.png						#copy over the new wallpaper
    cp [PATH TO BACKGROUND] /usr/share/backgrounds/xfce/xfce-verticals.png						#copy over the new wallpaper
  fi

  ##########################################################################################################
  #Documentation: copy the new wallpaper from its location in the network drive to the computer            #
  #also copies the old wallpaper to [wallpaper_name]_old.png so that the user can still use it if they want#
  #The process varies if the computer is running mint or ubuntu, hence the if/else statement               #
  ##########################################################################################################

  echo "echo Hey! | figlet && neofetch" >> /home/${current_username}/.bashrc						#this tells bash to display a neat set of system info for

  cp [PATH TO NEW .bashrc FILE] /home/$current_username/										#this copies a default .bash_aliases to your home

  echo "ME" | figlet		#show a fancy ME (or any text you want)
  neofetch				    #display system info
  ##########################################################################################################
  #Documentation: figlet and neofetch are neat programs that do cool command line things.                  #
  ##########################################################################################################
  echo "" >> $filename
  echo "" >> $lfilename
}


#=================== Matlab? =======================
install_matlab() {
  #[INTERNALLY, we use Matlab frequently. none of this will work if you don't have your own access to the proper installer and a file installation key and license.
  # but I left this in for reference in case it helps anyone] 
  echo "************ Matlab **********" >> $filename
  echo "************ Matlab **********" >> $lfilename

  matlab='y'															#install matlab by default

  echo "Chose $matlab to install matlab" >> $filename					#tell the logfile what we chose about installing matlab
  if [[ $matlab == 's' ]]; then											#if you type 's', then you can install non-silently
    xhost + SI:localuser:root &>> $filename								#allow root to run the gui installer (yes you need to run the installer as root)
    gedit [Location of File Installation Key Text Document] &			#open a gui of the file installation key
    #the above line uses & at the end to run this in the background. Note that the installer (next command) should not be run in the background, as we want
    #to wait for the install to finish before finishing the script.
    ./[PATH to matlab installer]										#launch the installer
    echo "launched gui matlab installer" >> $filename					#log that we started the gui installer.
  fi

  if [[ $matlab == 'y' ]]; then											#do the silent install
    xhost + SI:localuser:root &>> $filename								#allow root to run the installer
    ./[PATH to matlab installer] -inputFile [PATH to the input file for the installer]
    #the above line runs the silent installer
    echo "launched matlab silent installer" >> $filename				#tell the logfile that we started the silent installer
    ln -s /usr/local/matlab-2021b/bin/matlab /usr/local/bin/matlab &>> $filename	#create symbolic links the matlab executable
    cat /tmp/matlab-install.log >> $lfilename							#read the matlab install log into the end of the longlog file so we know how the install went
  fi

  ##########################################################################################################
  #Documentation: Can you help me install matlab? yes. This will install Matlab R2021 silently [Internally,#
  #this works, with access to the installer located on the networked drive, and the proper licenses to     #
  #install matlab this way]  																			   #
  ##########################################################################################################
}


#========= END OF LOG FILE =======================
end_of_logs() {
echo "************** END OF LOG FILE **************" >> $filename
echo "************** END OF LONGLOG FILE **************" >> $lfilename

cp ${filename} [Network Drive Location where the post install script is stored]/.logs/		#copy the logfile to [network drive]/.logs 
cp ${lfilename} [Network Drive Location]/.logs/												#copy the longlogfile to [network drive]/.logs, so we can go back and revisit these to see what happend.
}


#========= END OF SCRIPT =======================
end_of_script() {
rm post-install.sh			#remove the post-install script
rm $filename				#remove log file
rm $lfilename				#remove longlog file
echo "All done"				#All done.
exit						#end of program
}


check_root					#make sure this is being executed as root, or with sudo
begin_logs					#start the log files
begin_script				#do the first few parts of the script
map_s_drive					#map the S:\ drive
#change_default_password	#OPTIONAL - set the default password while the script is being run
add_users					#add users
install_updates				#install updates 
eesi 						#install other apps
set_up_ssh					#set up ssh and ufw
misc_config					#other configuration (background)
install_matlab				#install matlab (optional)
end_of_logs					#close the log files and put them in the S:\ drive
end_of_script				#finish the script
