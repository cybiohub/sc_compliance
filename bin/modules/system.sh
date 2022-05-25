#! /bin/bash
#set -x
# ## (c) 2004-2022  Cybionet - Ugly Codes Division
# ## v1.6 - May 24, 2022


# ############################################################################################
# ## SYSTEM

# ## Retrieves the OS version.
function actualVersion {
 osVersion="$(hostnamectl | grep "Operating System" | awk -F  ":" '{print $2}' | sed 's/^ //g')"
 doVersion="$(do-release-upgrade -c | grep "New release" | awk -F " " '{print $3}' | sed 's/^.//g')"

 if [ -n "${doVersion}" ]; then
   echo -e "\tOS version: \e[31m${osVersion}\e[0m"
   echo -e "\t\t[\e[31mCheck a new version is available: ${doVersion}\e[0m]\n"
   critical=$((critical+1))
 else
   echo -e "\tOS version: ${osVersion}\n"
 fi
}

# ## Check if the system requires a reboot.
# ## Result: 0 (Ok), 1 (Reboot).
function rebootNeeded() {
 if [ -f '/var/run/reboot-required' ]; then
   echo -e '\tReboot Needed: \e[31mYes\e[0m'
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
   echo -e '\tUpgrade Packages Available: \e[31mYes\e[0m'
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
   echo -e '\tRemove Packages: \e[31mYes\e[0m'
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

 # ## Check sourced.list file.
 sourceSStatus=$(</etc/apt/sources.list grep -v "${osVersion}" | sed '/^\s*$/d' | grep -c -v "^#")

 if [ "${sourceSStatus}" -ne 0 ]; then
   echo -e "\t\tSource \"sources,list}\": \e[31mCritical\e[0m"
   critical=$((critical+1))
 else
   echo -e "\t\tSource \"sources.list\": \e[32mOk\e[0m"
   pass=$((pass+1))
 fi

 # ## Check files in sourced.list.d.
 for file in /etc/apt/sources.list.d/*
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

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END