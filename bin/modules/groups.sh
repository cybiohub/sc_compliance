#! /bin/bash
#set -x
# ## (c) 2004-2025  Cybionet - Ugly Codes Division
# ## v1.8 - December 23, 2024


# ############################################################################################
# ## GROUPS

# ## Permissions on 'group' files.
groupPerm() {
    # ## Set 'group' file paths.
    local groupFiles=("/etc/group" "/etc/group-")

     echo -e "\n\n\tPermissions on group files:"

    # ## Loop to check each file.
    for grpFile in "${groupFiles[@]}"; do
        if [ -e "${grpFile}" ]; then
            # ## Retrieving permissions.
            permissions=$(stat -c "%a" "${grpFile}")
            file=$(echo "${grpFile}" | awk -F '/' '{print $3}')

            # ## Check if permissions are not 644.
            if [ "${permissions}" -ne 644 ]; then
                echo -e "\t\t\"${grpFile}\" permission: \e[31mCritical\e[0m \n\t\t\t[\e[31mPlease set permission to '644' for ${file} file.\e[0m]"

                critical=$((critical+1))
            else
                echo -e "\t\tPermission on \"${file}\" file: \e[32mOk\e[0m (${permissions})"
                pass=$((pass+1))
            fi
        fi
    done
}


# ## Duplicate GID [6.2.17 Ensure no duplicate GIDs exist]
function uniqueGID() {
 uniqGid=$(getent group | cut -d: -f3 | sort -n | uniq -d | awk -F " " '{print $1","}' | sed -z 's/\n//g' | sed 's/,$//g')

 if [ ! -z "${uniqGid}" ]; then
  echo -e "\n\tDuplicate GIDs exist: \e[31mError\e[0m"
  echo -e "\t\tConflicting GID: ${uniqGid}"
  critical=$((critical+1))
 fi
}

function groupIntegrity() {
 grpSanity="$(grpck -r)"

 if [ -z "${grpSanity}" ]; then
   echo -e "\tGroups file integrity: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\n\tGroups file integrity: \e[31mError\e[0m"
   echo -e "\t\tMessage:\n ${grpSanity}"
   critical=$((critical+1))
 fi
}

function groupCheck() {
 echo -e -n "\n\tGroup root:"

 grpRoot="$(awk -F':' '/root/{print $4}' /etc/group)"
 nbrRoot="$(echo "${grpRoot}" | awk -F ":" '{print $1}' | awk -F "," '{print NF}' )"

 echo -n -e "\e[33m${grpRoot}\e[0m "

 if (( "${nbrRoot}" <= 1 )); then
   echo -e "\e[32mOk\e[0m (${nbrRoot})"
   pass=$((pass+1))
 else
   echo -e " \e[31mCritical\e[0m (${nbrRoot})"
   echo -e "\t\t[\e[31mVeuillez enlever tous les membres de ce groupe\e[0m]"
   critical=$((critical+1))
 fi

 echo -e -n "\tGroup sudo: "

 grpSudo=$(awk -F':' '/sudo/{print $4}' /etc/group)
 nbrSudo=$(echo "${grpSudo}" | awk -F ":" '{print $1}' | awk -F "," '{print NF}' )

 echo -n -e "\e[33m${grpSudo}\e[0m "

 if (( "${nbrSudo}" <= 3 )); then
   echo -e "\e[32mOk\e[0m (${nbrSudo})"
   pass=$((pass+1))
 else
   echo -e "\e[31mErreur\e[0m (${nbrSudo})"
   echo -e "\t\t[\e[31mVeuillez réduire votre nombre de membre au groupe à trois et moins\e[0m]"
   critical=$((critical+1))
 fi

 echo -e -n "\tGroup restricted: "
 grpRestricted="$(awk -F':' '/restricted/{print $4}' /etc/group)"
 nbr=$(echo "${grpRestricted}" | awk -F ":" '{print $1}' | awk -F "," '{print NF}' )

 if (( "${nbr}" <= 3 )); then
   echo -n -e "\e[33m${grpRestricted}\e[0m \e[32mOk\e[0m (${nbr})"
   pass=$((pass+1))
 else
   echo -e "\e[33m${grpRestricted}\e[0m (${nbr})"
   echo -e "\t\t[\e[31mReduce the number of members in the restricted group.\e[0m]"
   critical=$((critical+1))
 fi
}


# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\e[34m[GROUPS]\e[0m"

# ## Check.
groupIntegrity
groupCheck

uniqueGID

# ##
groupPerm


# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
