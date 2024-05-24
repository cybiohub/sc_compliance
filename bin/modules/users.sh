#! /bin/bash
#set -x
# ## (c) 2004-2023  Cybionet - Ugly Codes Division
# ## v1.6 - June 28, 2023


# ############################################################################################
# ## USERS

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

 if [ ! -z ${#unusedUsers[@]} ]; then
   echo -e -n "\n\tUnused User: \e[31mCritical\e[0m (${#unusedUsers[@]})\n\t\t[\e[31mConsider deleting users who are not used.\e[0m]\n"

   for uusers in "${unusedUsers[@]}"
   do
     echo -e "\t\t   - $uusers"
   done
   critical=$((critical+1))
 else
   echo -e -n "\n\tUnused User: \e[32mOk\e[0m\n"
   pass=$((pass+1))
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


# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
