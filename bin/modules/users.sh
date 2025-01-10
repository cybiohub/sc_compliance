#! /bin/bash
#set -x
# ## (c) 2004-2025  Cybionet - Ugly Codes Division
# ## v1.8 - December 23, 2024


# ############################################################################################
# ## USERS

# ## Permissions on 'passwd' files.
passwdPerm() {
    # ## Set 'passwd' file paths.
    local passwdFiles=("/etc/passwd" "/etc/passwd-")

     echo -e '\n\tPermissions on passwd files:'

    # ## Loop to check each file.
    for userFile in "${passwdFiles[@]}"; do
        if [ -e "${userFile}" ]; then
            # ## Retrieving permissions.
            permissions=$(stat -c "%a" "${userFile}")
	    file=$(echo "${userFile}" | awk -F '/' '{print $3}')

            # ## Check if permissions are not 644.
            if [ "${permissions}" -ne 644 ]; then
		echo -e "\t\t\"${userFile}\" permission: \e[31mCritical\e[0m (${permissions})\n\t\t\t[\e[31mPlease set permission to '644' for ${file} file.\e[0m]"

                critical=$((critical+1))
            else
		    echo -e "\t\tPermission on \"${file}\" file: \e[32mOk\e[0m (${permissions})"
     		pass=$((pass+1))
            fi
        fi
    done
}


# ## Permissions on 'shadow' files.
shadowPerm() {
    # ## Set 'shadow' file paths.
    local shadowFiles=("/etc/shadow" "/etc/shadow-")

     echo -e '\n\tPermissions on shadow files:'

    # ## Loop to check each file.
    for shwFile in "${shadowFiles[@]}"; do
        if [ -e "${shwFile}" ]; then
            # ## Retrieving permissions.
            permissions=$(stat -c "%a" "${shwFile}")
            file=$(echo "${shwFile}" | awk -F '/' '{print $3}')

            # ## Check if permissions are not 640.
            if [ "${permissions}" -ne 640 ]; then
                echo -e "\t\t\"${shwFile}\" permission: \e[31mCritical\e[0m (${permissions})\n\t\t\t[\e[31mPlease set permission to '640' for ${file} file.\e[0m]"

                critical=$((critical+1))
            else
                echo -e "\t\tPermission on \"${file}\" file: \e[32mOk\e[0m (${permissions})"
     		pass=$((pass+1))
            fi
        fi
    done
}

# ## Duplicate UID [6.2.16 Ensure no duplicate UIDs exist]
function uniqueUID() {
 uniqUid=$(getent passwd | cut -d: -f3 | sort -n | uniq -d | awk -F " " '{print $1","}' | sed -z 's/\n//g' | sed 's/,$//g')

 if [ ! -z "${uniqUid}" ]; then
  echo -e "\tDuplicate UIDs exist: \e[31mError\e[0m"
  echo -e "\t\tConflicting UID: ${uniqUid}\n"
  critical=$((critical+1))
 fi
}

# ## Duplicate User [6.2.18 Ensure no duplicate user names exist]
function uniqueUser() {
 uniqUser=$(getent passwd | cut -d: -f1 | sort -n | uniq -d | awk -F " " '{print $1","}' | sed -z 's/\n//g' | sed 's/,$//g')

 if [ ! -z "${uniqUser}" ]; then
  echo -e "\tDuplicate Users exist: \e[31mError\e[0m"
  echo -e "\t\tConflicting User: ${uniqUser}\n"
  critical=$((critical+1))
 fi
}

# ##
function userIntegrity() {
 usrSanity="$(pwck -r | grep -v "does not exist")"

 if [ -z "${usrSanity}" ]; then
   echo -e '\tUsers file integrity: \e[32mOk\e[0m'
   pass=$((pass+1))
 else
   echo -e '\tUsers file integrity: \e[31mError\e[0m'
   echo -e "\t\tMessage:\n\t\t\t${usrSanity}"
   critical=$((critical+1))
 fi
}

# ##
function loginDefs() {
 sysUidMin="$(</etc/login.defs grep "^SYS_UID_MIN" | awk -F " " '{print $2}')"

 if [ -z "${sysUidMin}" ]; then
   echo -e '\tRange of user IDs used for the creation of system users: \e[31mCritical\e[0m \n\t\t[\e[31mPlease set the "SYS_UID_MIN" parameter to "100" in /etc/login.defs file.\e[0m]'
   critical=$((critical+1))
 else

   if [ "${sysUidMin}" -le 100 ]; then
     echo -e "\tRange of UIDs used for the creation: \e[32mOk\e[0m (${sysUidMin})"
     pass=$((pass+1))
   else
   echo -e '\tRange of user IDs used for the creation of system users: \e[31mCritical\e[0m \n\t\t[\e[31mPlease set the "SYS_UID_MIN" parameter to "100" in /etc/login.defs file.\e[0m]'
   critical=$((critical+1))
   fi
 fi
}

# ##
function passMin() {
 passMinDays=$(</etc/login.defs grep "^PASS_MIN_DAYS" | awk -F " " '{print $2}')

 if [ -z "${passMinDays}" ]; then
   echo -e "\tEnsure minimum days between password changes is 7 or more in /etc/login.defs"
   critical=$((critical+1))
 else
   if [ "${passMinDays}" -le 7 ]; then
     echo -e "\tMinimum days between password changes: \e[32mOk\e[0m (${passMinDays})"
     pass=$((pass+1))
   else
     echo -e '\tMinimum days between password changes: \e[31mCritical\e[0m (${passMinDays})\n\t\t[\e[31mPlease set the "PASS_MIN_DAYS" parameter to "7" or more\e[0m]'
     critical=$((critical+1))
   fi
 fi
}


# ## Consider deleting users who are not used.
function unusedUsers() {
 lastUser=$(getent passwd | grep -vE 'nobody|false' | awk -F: '$3 > 999 {print $1}')

 for luser in ${lastUser[@]}; do
   lastLog=$(lastlog -b 0 -t 90 -u "${luser}")

   # ## Show unused users.
   if [ -z "${lastLog}" ]; then
     unusedUsers+=("${luser}")
   fi
 done

 if [ "${#unusedUsers[@]}" == 0 ]; then
   echo -e -n "\n\tUnused User: \e[32mOk\e[0m\n"
   pass=$((pass+1))
 else
   echo -e -n "\n\tUnused User: \e[31mCritical\e[0m (${#unusedUsers[@]})\n\t\t[\e[31mConsider deleting users who are not used.\e[0m]\n"

   for uusers in "${unusedUsers[@]}"
   do
     echo -e "\t\t   - $uusers"
   done
   critical=$((critical+1))
 fi
}


# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\e[34m[USERS]\e[0m"

# ## Check.
uniqueUID
uniqueUser

#userIntegrity
loginDefs
passMin

unusedUsers

# ## 
passwdPerm
shadowPerm


# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
