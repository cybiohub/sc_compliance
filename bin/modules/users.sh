#! /bin/bash
#set -x
# ## (c) 2004-2022  Cybionet - Ugly Codes Division
# ## v1.3 - April 06, 2022


# ############################################################################################
# ## USERS

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
 passDayMin=$(</etc/login.defs grep "^PASS_MIN_DAYS" | awk -F " " '{print $2}')

 if [ -z "${passDayMin}" ]; then
   echo -e "\tEnsure minimum days between password changes is 7 or more in /etc/login.defs"
   critical=$((critical+1))
 else
   if [ "${passDayMin}" -le 7 ]; then
     echo -e "\tMinimum days between password changes: \e[32mOk\e[0m (${passDayMin})"
     pass=$((pass+1))
   else
     echo -e "\tMinimum days between password changes: \e[31mCritical\e[0m (${passDayMin})\n\t\t[\e[31mEnsure minimum days between password changes is 7 or more\e[0m]"
     critical=$((critical+1))
   fi
 fi
}


# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\e[34m[USERS]\e[0m"

# ## Check.
userIntegrity
loginDefs
passMin

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
