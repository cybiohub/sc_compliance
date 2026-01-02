#! /bin/bash
#set -x
# ## (c) 2004-2026  Cybionet - Ugly Codes Division
# ## v1.18 - January 01, 2026


# ############################################################################################
# ## SYSTEM

# ## Retrieves the OS version.
function actualVersion() {
 # ## Retrieving the full version of Ubuntu.
 osVersion="$(hostnamectl | grep "Operating System" | awk -F  ":" '{print $2}' | sed 's/^ //g')"
 ubuntuVersion="$(lsb_release -rs)"
 codename="$(lsb_release -cs)"

 # ## Table of LTS versions and their end-of-life dates.
 declare -A eol_dates
 eol_dates["16.04"]="2021-04-30"
 eol_dates["18.04"]="2023-05-31"
 eol_dates["20.04"]="2025-05-31"
 eol_dates["22.04"]="2027-04-30"
 eol_dates["24.04"]="2029-04-30"

 if [[ "${osVersion}" =~ ^Ubuntu.* ]]; then
   # ## Check if a newer version is available.
   doVersion="$(do-release-upgrade -c | grep "New release" | awk -F " " '{print $3}' | sed 's/^.//g')"

   # ## Check if the current version is in EOL.
   eol_date="${eol_dates[$ubuntuVersion]}"
   current_date=$(date +%Y-%m-%d)

   if [[ -n "${eol_date}" && "${current_date}" > "${eol_date}" ]]; then
     eol_notice="\t\t[\e[31mWARNING: This version is End Of Life since ${eol_date}\e[0m]"
     critical=$((critical+1))
   elif [[ -n "${eol_date}" ]]; then
     eol_notice="[EOL Date: ${eol_date}]"
   else
     eol_notice="[EOL Date: Unknown]"
   fi

   # ## Final display.
   if [[ -n "${doVersion}" ]]; then
     echo -n -e "\tOS version: \e[31m${osVersion}\e[0m"
     echo -e " ${eol_notice}"
     echo -e "\t\t[\e[31mNew version available: ${doVersion}\e[0m]\n"
     critical=$((critical+1))
   else
     echo -e "\tOS version: ${osVersion}"
   fi
 else
   echo -e "\tOS version: ${osVersion}"
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
function needUpgrade() {
 # ## Retrieves the apt upgrade summary, without installing.
 OUT=$(apt-get -s upgrade)

 # ## Count the occurrences.
 upGraded=$(echo "${OUT}" | grep -Eo '[0-9]+ upgraded' | awk '{print $1}')
 notUpGraded=$(echo "${OUT}" | grep -Eo '[0-9]+ not upgraded' | awk '{print $1}')

 # ## Default values if empty.
 upGraded=${upGraded:-0}
 notUpGraded=${notUpGraded:-0}

 # ## Return rules.
 if [ "$upGraded" -gt 0 ]; then
   # ## There is at least 1 package to update.
   echo -e '\tUpgrade Packages Available: \e[33mYes\e[0m'
   warning=$((warning+1))
 elif [ "$notUpGraded" -gt 0 ]; then
   # ## None upgraded, but there are "not upgraded" ones.
   echo -e '\tUpgrade packages listed, but not available.: \e[32mYes\e[0m'
   pass=$((pass+1))
 else
   # ## No upgrades or not-upgraded.
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
 sourceFiles=$(find /etc/apt/sources.list.d/ \( -name "*.list" -o -name "*.source" \) -maxdepth 1 -type f 2>/dev/null | wc -l)


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
      sourceDStatus=$(grep -c 'distUpgrade$\|save$' "${file}")
      sourceFile=$( echo "${mySource}" | awk -F "/" '{print $5}')

     if [ "${sourceDStatus}" -ne 0 ]; then
       echo -e "\t\tSource \"${sourceFile}\": \e[33mWarning\e[0m"
       echo -e '\t\t\t[\e[33mPlease consider removing this file.\e[0m]'
       warning=$((warning+1))
     fi
   done
 fi


 sourceFailed=$(ls /var/lib/apt/lists/partial | grep -c -e "FAILED$")

 if [ "${sourceFailed}" -ne 0 ]; then
   echo -e "\t\tSource Failed: \e[31mCritical\e[0m (${sourceFailed})"
   critical=$((critical+1))
 else
   echo -e "\t\tSource Failed: \e[32mNone\e[0m (${sourceFailed})"
   pass=$((pass+1))
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
     echo -e "\t\tcron.${crons}: \e[31mCritical\e[0m (${cronPerm}) \n\t\t\t[\e[31mEnsure permissions on /etc/cron.${crons} are configured to 700.\e[0m]"
     critical=$((critical+1))
   fi
 done
}

function repoCrontabPerm() {
 echo -e '\n\tCrontab file:'
 crontabPerm="$(stat -c "%a" /etc/crontab)"	 

 if [ "${crontabPerm}" -eq 600 ]; then
   echo -e -n "\t\tcrontab file: \e[32mOk\e[0m (${crontabPerm})\n"
   pass=$((pass+1))
 else
   echo -e -n "\t\tcrontab file: \e[31mCritical\e[0m (${crontabPerm}) \n\t\t\t[\e[31mEnsure permissions on /etc/crontab are configured to 600.\e[0m]\n"
   critical=$((critical+1))
 fi
}

function fileWithouOwner() {
 declare -a fileWoOwner
 mapfile -t fileWoOwner < <(/usr/bin/find / -nouser -nogroup -print 2>/dev/null)

 if [ "${#fileWoOwner[@]}" -eq 0 ]; then
   echo -e "\tFiles without owner: \e[32mOk\e[0m (${#fileWoOwner[@]})"
   pass=$((pass+1))
 else
   echo -e "\tFiles without owner: \e[31mCritical\e[0m (${#fileWoOwner[@]}) \n\t\t[\e[31mMake sure all files on your system have an owner or group owner.\e[0m]"
   printf '\t\t- %s\n' "${fileWoOwner[@]}"
   critical=$((critical+1))
 fi
}

function runAsRoot() {
 # ## Check if the script are running with sudo or under root user.
 if [ "${EUID}" -ne 0 ] ; then
  echo -e "\n\e[33mCAUTION: The 'system module' must be run with sudo or as root.\e[0m"
 fi
}


# ############################################################################################
# ## EXECUTION

# ##
runAsRoot

# ## Header.
echo -e "\n\e[34m[OPERATION SYSTEM]\e[0m"

# ## Check.
actualVersion
rebootNeeded
needUpgrade
removePackage
sourcesRepo

# ## Header.
echo -e "\n\e[34m[FILES]\e[0m"
fileWithouOwner

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
