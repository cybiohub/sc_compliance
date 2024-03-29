#! /bin/bash
#set -x
# ## (c) 2004-2023  Cybionet - Ugly Codes Division
# ## v1.4 - November 05, 2023


# ############################################################################################
# ## VARIABLES

readonly UNWANTEDPKG='minidlna nmap rsh-server samba snmpd tcpdump telnet'
readonly WANTEDPKG='crowdsec lynis ubuntu-advantage-tools' # aide


# ############################################################################################
# ## PACKAGES

function pkgWanted() {
 echo -e "\tWanted packages:"
 declare -a checkPkgW=($(printf "${WANTEDPKG}"))

 for item in "${checkPkgW[@]}"; do
   checkPackage "${item}"

   # ## Check if the package is installed.
   # ## Result: 0=Missing, 1=Installed
   if [ "${dependency}" -eq 0 ]; then
     echo -e "\t\t${item}: \e[33mWarning\e[0m"
     echo -e "\t\t\t[\e[33mPlease consider to install and run ${item}.\e[0m]"
     warning=$((warning+1))
   else
     echo -e "\t\t${item}: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi
 done
}

function pkgUnwanted() {
 echo -e "\n\tUnwanted packages:"
 declare -a checkPkgU=($(printf "${UNWANTEDPKG}"))

 for item in "${checkPkgU[@]}"; do
   checkPackage "${item}"

   # ## Check if the package is installed.
   # ## Result: 0=Missing, 1=Installed
   if [ "${dependency}" -eq 1 ]; then
     echo -e "\t\t${item}: \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mPlease consider to uninstall ${item}. If the package is already uninstalled, use the 'dpkg -P ${item}' command.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\t\t${item}: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi
 done
}

# ## Checks for the presence of the package.
function checkPackage() {
 REQUIRED_PKG="${1}"
 if ! dpkg-query -s "${REQUIRED_PKG}" > /dev/null 2>&1; then
   dependency=0
 else
   dependency=1
 fi
}


# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\e[34m[PACKAGES]\e[0m"

# ## Check.
pkgWanted
pkgUnwanted

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
