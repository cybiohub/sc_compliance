#! /bin/bash
#set -x
# ## (c) 2004-2023  Cybionet - Ugly Codes Division
# ## v1.11 - July 17, 2023


# ############################################################################################
# ## SYSTEM

# ## Retrieves the OS version.
function actualVersion {
 osVersion="$(hostnamectl | grep "Operating System" | awk -F  ":" '{print $2}' | sed 's/^ //g')"

 if [[ "${osVersion}" =~ ^Ubuntu* ]]; then
   doVersion="$(do-release-upgrade -c | grep "New release" | awk -F " " '{print $3}' | sed 's/^.//g')"
   
   if [ -n "${doVersion}" ]; then
     echo -e "\tOS version: \e[31m${osVersion}\e[0m"
     echo -e "\t\t[\e[31mCheck a new version is available: ${doVersion}\e[0m]\n"
     critical=$((critical+1))
   else
     echo -e "\tOS version: ${osVersion}\n"
   fi
 fi
}

# ## Check if the system requires a reboot.
# ## Result: 0 (Ok), 1 (Reboot).
function rebootNeeded() {
 if [ -f '/var/run/reboot-required' ]; then
   echo -e '\tReboot Needed: \e[33mYes\e[0m'
   warning=$((warning+1))
 else
   echo -e '\tReboot Needed: \e[32mNo\e[0m'
   pass=$((pass+1))
 fi
}

# ## System need upgrade.
# ## Result: 0 (Ok), 1 (Need Upgrade)
function needUpgrade() {
 declare -i checkNumber
 checkNumber="$(apt-get -s dist-upgrade | grep 'upgraded,' | sed 's/[^0-9]*//g')"
 if [ "${checkNumber}" -ne 0 ]; then
   echo -e '\tUpgrade Packages Available: \e[33mYes\e[0m'
   warning=$((warning+1))
 else
   echo -e '\tUpgrade Packages Available: \e[32mNo\e[0m'
   pass=$((pass+1))
 fi
}

# ## Packages need to be remove.
# ## Result: 0 (Ok), 1+ (Remove).
function removePackage() {
 declare -i checkRemove
 checkRemove="$(apt-get --dry-run autoremove | grep -Po '^Remv \K[^ ]+' | wc -l)"
 if [ "${checkRemove}" -ne 0 ]; then
   echo -e '\tRemove Packages: \e[33mYes\e[0m'
   warning=$((warning+1))
 else
   echo -e '\tRemove Packages: \e[32mNo\e[0m'
   pass=$((pass+1))
 fi
}

function sourcesRepo() {
 # ## Sub-Header.
 echo -e '\n\tSources Repositories:'

 osVersion=$(</etc/os-release grep 'VERSION_CODENAME' | awk -F "=" '{print $2}')

 # ## Check sources.list file.
 sourceSStatus=$(</etc/apt/sources.list grep -v "${osVersion}" | sed '/^\s*$/d' | grep -c -v "^#")

 if [ "${sourceSStatus}" -ne 0 ]; then
   echo -e "\t\tSource \"sources.list}\": \e[31mCritical\e[0m"
   critical=$((critical+1))
 else
   echo -e "\t\tSource \"sources.list\": \e[32mOk\e[0m"
   pass=$((pass+1))
 fi

 # ## Check files in sourced.list.d.
 sourceFiles=$(find /etc/apt/sources.list.d/ -maxdepth 1 -type f | wc -l)

 if [ "${sourceFiles}" -gt 0 ]; then
   for file in /etc/apt/sources.list.d/*.list
   do
       mySource="${file}"
       sourceDStatus=$(grep -v "${osVersion}" "${file}" | grep -v "^#" | sed '/^\s*$/d' | wc -l)
       sourceFile=$( echo "${mySource}" | awk -F "/" '{print $5}')

     if [ "${sourceDStatus}" -ne 0 ]; then
       echo -e "\t\tSource \"${sourceFile}\": \e[31mCritical\e[0m"
       critical=$((critical+1))
     else
       echo -e "\t\tSource \"${sourceFile}\": \e[32mOk\e[0m"
       pass=$((pass+1))
     fi
   done

for file in /etc/apt/sources.list.d/*
   do
       mySource="${file}"
       sourceDStatus=$(ls "${file}" | grep 'distUpgrade$\|save$' | wc -l)
       sourceFile=$( echo "${mySource}" | awk -F "/" '{print $5}')

     if [ "${sourceDStatus}" -ne 0 ]; then
       echo -e "\t\tSource \"${sourceFile}\": \e[33mWarning\e[0m"
       echo -e '\t\t\t[\e[33mPlease consider removing this file.\e[0m]'
       warning=$((warning+1))
     fi
   done
 fi
}


function repoCronPerm() {
 # ## Sub-Header.
 echo -e '\tCron Repositories:'
 cronrepo=( "hourly" "daily" "weekly" "monthly" "d" )

 for crons in "${cronrepo[@]}"
 do
   cronPerm="$(stat -c "%a" /etc/cron."${crons}")"

   if [ "${cronPerm}" -eq 700 ]; then
     echo -e "\t\tcron.${crons}: \e[32mOk\e[0m (${cronPerm})"
     pass=$((pass+1))
   else
     echo -e "\t\tcron.${crons}: \e[31mCritical\e[0m (${cronPerm}) \n\t\t\t[\e[31mEnsure permissions on /etc/cron.${crons} are configured to 600.\e[0m]"
     critical=$((critical+1))
   fi
 done
}

function repoCrontabPerm() {
 echo -e '\n\tCrontab file:'
 crontabPerm="$(stat -c "%a" /etc/crontab)"	 

 if [ "${crontabPerm}" -eq 600 ]; then
   echo -e "\t\tcrontab file: \e[32mOk\e[0m (${crontabPerm})"
   pass=$((pass+1))
 else
   echo -e "\n\t\tcrontab file: \e[31mCritical\e[0m (${crontabPerm}) \n\t\t\t[\e[31mEnsure permissions on /etc/crontab are configured to 600.\e[0m]"
   critical=$((critical+1))
 fi
}


# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\e[34m[OPERATION SYSTEM]\e[0m"

# ## Check.
actualVersion
rebootNeeded
needUpgrade
removePackage
sourcesRepo

# ## Header.
echo -e "\n\e[34m[CRON]\e[0m"
repoCronPerm
repoCrontabPerm

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"


# ## END
