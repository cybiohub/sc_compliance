#! /bin/bash
#set -x
# ## (c) 2004-2022  Cybionet - Ugly Codes Division
# ## v1.2 - December 20, 2022


# ############################################################################################
# ## SUDOERS RULES

# ## Check sudoers.
function sudoCheck() {
 sudoers=$(</etc/sudoers grep -v "^#" | grep -v "^Defaults" | sed '/^\s*$/d' | grep "%" | awk -F " " '{print $1}' | sed 's/%//g' | tr '\n' ' ' | sed 's/ /,/g')
 sudoers+=$(cat /etc/sudoers.d/* | grep -v "^#" | grep -v "^Defaults" | sed '/^\s*$/d' | awk -F " " '{print $1}' | sed 's/%//g' | sort | uniq | tr '\n' ' ' | sed 's/ /,/g')
 sudoersMember=$(echo -n "${sudoers}" | sort | uniq | sed 's/,$//')
 sudoersCount=$(echo "${sudoersMember}" | awk -F',' '{print NF}')

 if (( "${sudoersCount}" <= 5 )); then
   echo -e "\tSudoers members: \e[33m${sudoersMember}\e[0m (${sudoersCount})"
   pass=$((pass+1))
 else
   echo -e "\tSudoers members: \e[33m${sudoersMember}\e[0m (${sudoersCount})"
   echo -e "\t\t[\e[31mReduce the number of members in the sudoers.\e[0m]"
   critical=$((critical+1))
 fi
}

# ## Check files in sourced.list.d.
function sudoLog() {
 sudoerFiles=$(find /etc/sudoers.d/ -maxdepth 1 -type f | wc -l)
 echo -e "\n\tSudoers rules:"
 if [ "${sudoerFiles}" -gt 0 ]; then
   for file in /etc/sudoers.d/*
   do
     mySudoer="${file}"

     sudoerDStatus=$(grep -v "Defaults logfile=" "${mySudoer}" | grep -v "^#" | sed '/^\s*$/d' | wc -l)
     sudoerFile=$( echo "${mySudoer}" | awk -F "/" '{print $4}')

     if [[ ! "${sudoerFile}" == "README" ]]; then
       if [ "${sudoerDStatus}" -eq 0 ]; then
         echo -e "\t\tSource \"${sudoerFile}\": \e[31mCritical\e[0m"
         echo -e "\t\t\t[\e[31mAdd 'Defaults logfile=\"/var/log/sudo.log\" to this file'.\e[0m]"
         critical=$((critical+1))
       else
         echo -e "\t\tSource \"${sudoerFile}\": \e[32mOk\e[0m"
         pass=$((pass+1))
       fi
     fi
   done
 fi

#grep -Ei '^\s*Defaults\s+logfile=\S+' /etc/sudoers /etc/sudoers.d/*
#
#find /etc/sudoers.d/ -type f | wc -l
#aDefaults
# logfile="/var/log/sudo.log"
}

# ## Access to the root account via su should be restricted to the 'root' group
# ## [CCE-15047-4]
function wheelGrpCheck() {
 wheelGrp=$(grep pam_wheel.so /etc/pam.d/su | grep "^# auth" | grep "use_uid$" | wc -l)
 
 grpWheel="$(awk -F':' '/wheel/{print $4}' /etc/group)"
 nbr=$(echo "${grpWheel}" | awk -F ":" '{print $1}' | awk -F "," '{print NF}' )

 echo -e -n "\n\tGroup wheel: "

 if (( "${wheelGrp}" == 1 )); then
   echo -n -e "\e[33m${grpWheel}\e[0m \e[32mOk\e[0m ("
   echo "${nbr})"
   pass=$((pass+1))
 else
   echo -n -e "\e[31m${grpWheel}\e[0m \e[31mCritical\e[0m ("
   echo "${nbr})"
   echo -e "\t\t[\e[31mAdd 'auth required pam_wheel.so use_uid' to the /etc/pam.d/su file. And put users on wheel group.\e[0m]"
   critical=$((critical+1))
 fi
}


function sudoLogCheck() {
 sudoLog="$(grep -cP '^[\s]*Defaults.*\blogfile=("(?:\\"|\\\\|[^"\\\n])*"\B|[^"](?:(?:\\,|\\"|\\ |\\\\|[^", \\\n])*)\b)\b.*$' /etc/sudoers)"

 echo -e -n "\n\tSudo Logfile: "

 if (( "${sudoLog}" == 1 )); then
   echo -n -e "\e[33m${sudoLog}\e[0m \e[32mOk\e[0m ("
   echo "${nbr})"
   pass=$((pass+1))
 else
   echo -e "\e[31mCritical\e[0m"
   echo -e "\t\t[\e[31mEnsure sudo logfile exists. Add 'Defaults logfile=/var/log/sudo.log' to the /etc/sudoers file.\e[0m]"
   critical=$((critical+1))
 fi
}

# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\e[34m[SUDO/SUDOERS]\e[0m"

sudoCheck
sudoLog
sudoLogCheck
wheelGrpCheck

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END

