#! /bin/bash
#set -x
# * **************************************************************************
# *
# * Author:        	(c) 2004-2022  Cybionet - Ugly Codes Division
# *
# * File:               launch.sh
# * Version:            0.1.2
# *
# * Description:        Script to check compliance of Ubuntu system.
# *
# * Creation: April 09, 2021
# * Change:   May 25, 2022
# *
# * **************************************************************************


#############################################################################################
# ## MODULES

declare -ir APACHE2=0
declare -ir AUDIT=1
declare -ir COMPLIANCE=1
declare -ir GROUPSS=1
declare -ir FIREWALL=1
declare -ir PACKAGES=1
declare -ir SECURITY=0
declare -ir SSH=1
declare -ir SYSTEM=1
declare -ir USERS=1


#############################################################################################
# ## VARIABLES

# ## Application informations.
appYear="$(date +%Y)"
appHeader="(c) 2004-${appYear}  Cybionet - Ugly Codes Division"
#appVersion='0.1.2'

# ## Declare initial status.
declare -i critical=0
declare -i warning=0
declare -i information=0
declare -i pass=0

# ## Location of this script.
location=$(dirname "${0}")


#############################################################################################
# ## VERIFICATION

clear

# ## Check if the script are running with sudo or under root user.
if [ "${EUID}" -ne 0 ] ; then
  echo -e "\n\e[34m${appHeader}\e[0m\n"
  echo -e "\n\n\n\e[33mCAUTION: This script must be run with sudo or as root.\e[0m"
  exit 0
else
  echo -e "\n\e[34m${appHeader}\e[0m"
  printf '%.s─' $(seq 1 "$(tput cols)")
  echo -e ""
fi


#############################################################################################
# ## EXECUTION

# ## System check rules.
if [ "${SYSTEM}" -eq 1 ]; then
  # shellcheck source=./modules/system.sh
  source "${location}/modules/system.sh"
fi

# ## Groups check rules.
if [ "${GROUPSS}" -eq 1 ]; then
  # shellcheck source=./modules/groups.sh
  source "${location}/modules/groups.sh"
fi

# ## Users check rules.
if [ "${USERS}" -eq 1 ]; then
  # shellcheck source=./modules/users.sh
  source "${location}/modules/users.sh"
fi

# ## Firewall check rules.
if [ "${FIREWALL}" -eq 1 ]; then
  # shellcheck source=./modules/iptables.sh
  source "${location}/modules/iptables.sh"
fi

# ## Security check rules.
if [ "${SECURITY}" -eq 1 ]; then
  # shellcheck source=./modules/security.sh
  source "${location}/modules/security.sh"
fi

# ## SSH check rules.
if [ "${SSH}" -eq 1 ]; then
  # shellcheck source=./modules/ssh.sh
  source "${location}/modules/ssh.sh"
fi

# ## Audit check rules.
if [ "${AUDIT}" -eq 1 ]; then
  # shellcheck source=./modules/audit.sh
  source "${location}/modules/audit.sh"
fi

# ## Packages check rules.
if [ "${PACKAGES}" -eq 1 ]; then
  # shellcheck source=./modules/packages.sh
  source "${location}/modules/packages.sh"
fi

# ## Apache2 check rules.
if [ "${APACHE2}" -eq 1 ]; then
  # shellcheck source=./modules/apache2.sh
  source "${location}/modules/apache2.sh"
fi

# ## Compliance check rules.
if [ "${COMPLIANCE}" -eq 1 ]; then
  # shellcheck source=./modules/compliance.sh
  source "${location}/modules/compliance.sh"
fi


#############################################################################################
# ## SUMMARY

   declare -i total=$(("${pass}" + "${critical}" + "${warning}"))

   if [[ -z "${total}" || "${total}" -eq 0 ]]; then
    somme=0
   else
     somme=$(bc -l <<< "scale=2;${pass}/${total}*100")
   fi

   echo -e -n "\n"
   printf '%.s─' $(seq 1 "$(tput cols)")
   
   echo -e "\n\n\e[33m[SUMMARY ${somme}%]\e[0m"

   if [ "${pass}" -eq 0 ]; then
     echo -e "\tPass: \t\t\e[31m${pass}\e[0m"
   else
     echo -e "\tPass: \t\t\e[32m${pass}\e[0m"
   fi

   if [ "${warning}" -eq 0 ]; then
     echo -e "\tWarning: \t\e[32m${warning}\e[0m"
   else
     echo -e "\tWarning: \t\e[33m${warning}\e[0m"
   fi

   if [ "${critical}" -eq 0 ]; then
     echo -e "\tCritical: \t\e[32m${critical}\e[0m"
   else
     echo -e "\tCritical: \t\e[31m${critical}\e[0m"
   fi

   if [ "${information}" -eq 0 ]; then
     echo -e "\tInformation: \t\e[34m${information}\e[0m"
   else
     echo -e "\tInformation: \t\e[34m${information}\e[0m"
   fi
   
   echo -e -n "\n"
   printf '%.s─' $(seq 1 "$(tput cols)")



# ## Exit.
exit 0

# ## END
