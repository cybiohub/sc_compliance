#! /bin/bash
#set -x
# ## (c) 2004-2025  Cybionet - Ugly Codes Division
# ## v1.7 - January 10, 2025


# ############################################################################################
# ## VARIABLES

readonly UNWANTEDPKG='minidlna nis nmap rsh-client rsh-server samba snmpd talk tcpdump telnet ttyd'
# ## Other Linux OS.
readonly WANTEDPKG='crowdsec lynis aide'
# ## Debian Linux OS.
readonly DWANTEDPKG='crowdsec lynis'
# ## Ubuntu Linux OS.
readonly UWANTEDPKG='crowdsec lynis ubuntu-advantage-tools'


# ############################################################################################
# ## PACKAGES

function pkgWanted() {
 echo -e "\tWanted packages:"

 if [ -x "$(command -v lsb_release)" ]; then
   distro=$(lsb_release -is)
   if [ "$distro" = "Ubuntu" ]; then
     declare -a checkPkgW=($UWANTEDPKG)
   elif [ "$distro" = "Debian" ]; then
     declare -a checkPkgW=($DWANTEDPKG)
   else
     declare -a checkPkgW=($WANTEDPKG)
   fi
 fi

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
