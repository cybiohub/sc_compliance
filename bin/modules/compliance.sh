#! /bin/bash
#set -x
# ## (c) 2004-2022  Cybionet - Ugly Codes Division
# ## v1.4 - April 05, 2022


# ############################################################################################
# ## COMPLIANCE

# ## Banner files.
#readonly fileIssue='/etc/issue'
#readonly fileIssueNet='/etc/issue.net' # ## Unused.


# ##
function orderExecutionVul() {
 declare -i isEmpty
 #isEmpty="$(ls -A /usr/local/bin/ | wc -l)"
 isEmpty="$(find /usr/local/bin/ -type f -printf '%T@ %f\n' | cut -d' ' -f2- | wc -l)"
 if [ "${isEmpty}" -eq 0 ]; then
   echo -e "\tLocal Bin Directory: \e[32mOk\e[0m (empty)"
   pass=$((pass+1))
 else
   #echo -e "\tLocal Bin Directory: \e[33mNot Empty\e[0m\n\t\t[\e[33mBe aware of the order of execution of applications. Do not use \"/usr/local/bin/\" directory.\e[0m]"
   #warning=$((warning+1))
   echo -e "\tLocal Bin Directory: \e[31mNot Empty\e[0m\n\t\t[\e[31mBe aware of the order of execution of applications. Do not use \"/usr/local/bin/\" directory.\e[0m]"
   critical=$((critical+1))
 fi
}

# ##
function hideCmdHistory() {
 declare -i hiddenCmd
# hiddenCmd="$(cat /root/.bashrc | grep ^HISTCONTROL | grep -c 'ignorespace')"
 hiddenCmd="$(</root/.bashrc grep ^HISTCONTROL | grep -c 'ignorespace')"

 if [ "${hiddenCmd}" -eq 0 ]; then
   echo -e '\tBashrc History Control: \e[32mOk\e[0m'
   pass=$((pass+1))
 else
   echo -e '\tBashrc History Control: \e[31mCritical\e[0m\n\t\t[\e[31mRemove the "ignorespace" value from the "HISTCONTROL" parameter in /root/.bashrc file.\e[0m]'
   critical=$((critical+1))
 fi
}

# ## Three Finger Salute.
function threeFingerSalute() {
 if [ -e '/etc/systemd/system/ctrl-alt-del.target' ]; then
   echo -e '\tCtrl+Alt+Del Disabled: \e[32mOk\e[0m'
   pass=$((pass+1))
 else
  echo -e '\tCtrl+Alt+Del Disabled: \e[31mCritical\e[0m\n\t\t[\e[31mDisable the "Ctrl+Alt+Del on the operating system.\e[0m]'
   critical=$((critical+1))
 fi
}

# ##
function pkgZabbixAgent() {
 APPDEP='zabbix-agent'
 checkPackage "${APPDEP}"

 # ## Check if zabbix-agent package is installed.
 # ## Result: 0=Missing, 1=Installed
 if [ "${dependency}" -eq 0 ]; then
   echo -e "\tZabbix Agent: \e[31mCritical\e[0m"
   echo -e "\t\t[\e[31mPlease consider to install ${APPDEP}.\e[0m]"
   critical=$((critical+1))
 else
   echo -e '\tZabbix Agent Installed: \e[32mOk\e[0m'
   pass=$((pass+1))
 fi
}

# ## Popularity Contest.
function popularityContest() {
 if [ -f /etc/cron.d/popularity-contest ]; then
  echo -e '\tPopularity Contest Disabled: \e[30mInformation\e[0m\n\t\t[\e[31mRemove annoying popularity contests.\e[0m]'
   information=$((information+1))
 else
   echo -e '\tPopularity Contest Disabled: \e[32mOk\e[0m'
   pass=$((pass+1))
 fi
}

# ##
function vimCheckBg() {
 declare -i vimBackground
 #vimBackground="$(cat /etc/vim/vimrc | grep "set background" | sed -e '/^"/d' | wc -l)"
 vimBackground="$(</etc/vim/vimrc grep "set background" | sed -e '/^"/d' | wc -l)"

 if [ "${vimBackground}" -eq 1 ]; then
   echo -e '\tVim Background Appy: \e[32mOk\e[0m'
   pass=$((pass+1))
 else
   echo -e '\tVim Background Apply: \e[31mCritical\e[0m\n\t\t[\e[30mSet the syntax highlighting and background for vim editor.\e[0m]'
   information=$((information+1))
 fi
}


# ############################################################################################
# ## GENERAL

# ##
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
echo -e "\n\e[34m[COMPLIANCE]\e[0m"

# ## Check.
orderExecutionVul
hideCmdHistory
threeFingerSalute
pkgZabbixAgent

# ## Header.
echo -e "\n\e[34m[ESTHETIC]\e[0m"

# ## Check.
vimCheckBg
popularityContest

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
