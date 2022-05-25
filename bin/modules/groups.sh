#! /bin/bash
#set -x
# ## (c) 2004-2022  Cybionet - Ugly Codes Division
# ## v1.4 - April 06, 2022


# ############################################################################################
# ## GROUPS

function groupIntegrity() {
 grpSanity="$(grpck -r)"

 if [ -z "${grpSanity}" ]; then
   echo -e "\tGroups file integrity: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\n\tGroups file integrity: \e[31mError\e[0m"
   echo -e "Message:\n ${grpSanity}"
   critical=$((critical+1))
 fi
}

function groupCheck() {
 echo -e -n "\n\tGroup root:"

 grpRoot="$(awk -F':' '/root/{print $4}' /etc/group)"
 nbrRoot="$(echo "${grpRoot}" | awk -F ":" '{print $1}' | awk -F "," '{print NF}' )"

 echo -n -e "\e[33m${grpRoot}\e[0m "

 if (("${nbrRoot}" <= '1' )); then
   echo -e "\e[32mOk\e[0m (${nbrRoot})"
   pass=$((pass+1))
 else
   echo -e " \e[31mCritical\e[0m (${nbrRoot})"
   echo -e "\t\t[\e[31mVeuillez enlever tous les membres de ce groupe\e[0m]"
   critical=$((critical+1))
 fi

# ROBERT
 echo -e -n "\tGroup sudo: "

 grpSudo=$(awk -F':' '/sudo/{print $4}' /etc/group)
 nbrSudo=$(echo "${grpSudo}" | awk -F ":" '{print $1}' | awk -F "," '{print NF}' )

 echo -n -e "\e[33m${grpSudo}\e[0m "

 if (("${nbrSudo}" <= '3' )); then
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

 if (("${nbr}" <= '3' )); then
   echo -n -e "\e[33m${grpRestricted}\e[0m \e[32mOk\e[0m ("
   echo "${nbr})"
   pass=$((pass+1))
 else
   echo -e "\e[33m${grpRestricted}\e[0m (${nbr})"
   echo -e "\t\t[\e[31mReduce the number of members in the restricted group.\e[0m]"
   critical=$((critical+1))
 fi
}


# ## ROBERT - Mettre en array
# ## Check sudoers.
function sudoCheck() {
 echo -e "\n\e[34m[SUDOERS]\e[0m"

 sudoers=$(</etc/sudoers grep -v "^#" | grep -v "^Defaults" | sed '/^\s*$/d' | grep "%" | awk -F " " '{print $1}' | sed 's/%//g' | tr '\n' ' ' | sed 's/ /,/g')
 sudoers+=$(cat /etc/sudoers.d/* | grep -v "^#" | grep -v "^Defaults" | sed '/^\s*$/d' | awk -F " " '{print $1}' | sed 's/%//g' | sort | uniq | tr '\n' ' ' | sed 's/ /,/g')
# sudoers+=$(cat /etc/sudoers.d/* | grep -v "^#" | grep -v "^Defaults" | sed '/^\s*$/d' | awk -F " " '{print $1}' | sed 's/%//g' | tr '\n' ' ' | sed 's/ *$//' | sed 's/ /,/g')
 #sudoersCount=$(echo "${sudoers}" | awk -F',' '{print NF}')
 sudoersMember=$(echo -n "${sudoers}" | sort | uniq)
 echo "${sudoersMember}"
 sudoersCount=$(echo "${sudoersMember}" | awk -F',' '{print NF}')

 if (("${sudoersCount}" <= '5' )); then
   echo -e "\tSudoers: \e[33m${sudoersMember}\e[0m (${sudoersCount})"
   pass=$((pass+1))
 else
   echo -e "\tSudoers: \e[33m${sudoersMember}\e[0m (${sudoersCount})"
   echo -e "\t\t[\e[31mReduce the number of members in the sudoers.\e[0m]"
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
sudoCheck

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
