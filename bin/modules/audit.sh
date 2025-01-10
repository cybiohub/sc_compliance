#! /bin/bash
#set -x
# ## (c) 2004-2025  Cybionet - Ugly Codes Division
# ## v1.4 - November 20, 2023


# grep -i denied /var/log/audit/audit.log   Pour trouver les apparmor="DENIED"


# ############################################################################################
# ## AUDIT

# ##  
function pkgAuditd() {
 APPDEP='auditd'
 checkPackage "${APPDEP}"

 # ## Check if auditd package is installed.
 # ## Result: 0=Missing, 1=Installed
 if [ "${dependency}" = 0 ]; then
   echo -e "\n\t${APPDEP^}: \e[31mCritical\e[0m"
   echo -e "\t\t[\e[31mPlease consider to install ${APPDEP}.\e[0m]"
   critical=$((critical+1))
 else
   echo -e "\n\tAuditd: \e[32mInstalled\e[0m\n"

   sysAuditd
 fi
}

# ##
function pkgAudispd() {
 APPDEP='audispd-plugins'
 checkPackage "${APPDEP}"

 # ## Check if audispd-plugins package is installed.
 # ## Result: 0=Missing, 1=Installed
 if [ "${dependency}" = 0 ]; then
   echo -e "\n\t${APPDEP^}: \e[31mCritical\e[0m"
   echo -e "\t\t[\e[31mPlease consider to install ${APPDEP}.\e[0m]"
   critical=$((critical+1))
 else
   echo -e "\n\tAudispd plugins: \e[32mInstalled\e[0m\n"
 fi
}

function sysAuditd() {
# ########################
# ## SSH
   # ##
   echo -e "\tSSH: "

   # ## V-219242 :: ssh-agent - OS must generate audit records for successful/unsuccessful uses of the ssh-agent command.
   auditdSSH=$(auditctl -l | grep '/usr/bin/ssh-agent')
   if [ -z "${auditdSSH}" ]; then
     echo -e "\t\tssh-agent: \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mAdd '-a always,exit -F path=/usr/bin/ssh-agent -F perm=x -F auid>=1000 -F auid!=-1 -k privileged-ssh' in /etc/audit/rules.d/stig.rules file.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\t\tssh-agent: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi

   # ## sshd_config - Logs every attempt to read or modify the /etc/ssh/sshd_config file.
   # -w /etc/ssh/sshd_config -p warx -k sshd_config
   auditdSSHConf=$(auditctl -l | grep '/etc/ssh/sshd_config')
   if [ -z "${auditdSSHConf}" ]; then
     echo -e "\t\tssh-config: \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mAdd '-w /etc/ssh/sshd_config -p warx -k sshd_config' in /etc/audit/rules.d/stig.rules file.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\t\tssh-config: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi

   # ## V-219243 :: ssh-keysign - OS must generate audit records for successful/unsuccessful uses of the ssh-keysign command.
   # -a always,exit -F path=/usr/lib/openssh/ssh-keysign -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged-ssh
   auditdSSHKeySign=$(auditctl -l | grep '/usr/lib/openssh/ssh-keysign')
   if [ -z "${auditdSSHKeySign}" ]; then
     echo -e "\t\tssh-keysign: \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mAdd '-a always,exit -F path=/usr/lib/openssh/ssh-keysign -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged-ssh' in /etc/audit/rules.d/stig.rules file.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\t\tssh-keysign: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi


# ########################
# ## SUDO
   echo -e "\n\tSUDO: "

   # ## V-219263 :: sudo - OS must generate audit records for successful/unsuccessful uses of the sudo command.
   # -a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=-1 -k priv_cmd
   auditdSudo=$(auditctl -l | grep '/usr/bin/sudo')
   if [ -z "${auditdSudo}" ]; then
     echo -e "\t\tsudo: \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mAdd '-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=-1 -k priv_cmd' in /etc/audit/rules.d/stig.rules file.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\t\tsudo: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi

   # ## V-219264 :: sudo - OS must generate audit records for successful/unsuccessful uses of the sudoedit command.
   # -a always,exit -F path=/usr/bin/sudoedit -F perm=x -F auid>=1000 -F auid!=4294967295 -k priv_cmd
   auditdSudo=$(auditctl -l | grep '/usr/bin/sudoedit')
   if [ -z "${auditdSudo}" ]; then
     echo -e "\t\tsudoedit: \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mAdd '-a always,exit -F path=/usr/bin/sudoedit -F perm=x -F auid>=1000 -F auid!=4294967295 -k priv_cmd' in /etc/audit/rules.d/stig.rules file.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\t\tsudoedit: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi

# ########################
# ## SYSTEM
   echo -e "\n\tSYSTEM CALL: "

   # ## V-219262 :: system call :: OS must generate audit records for successful/unsuccessful uses of the open_by_handle_at system call.
   auditdOpenByHandle=$(auditctl -l | grep 'open_by_handle_at')
   if [ -z "${auditdOpenByHandle}" ]; then
     echo -e "\t\tsystem call (open_by_handle): \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mAdd '\t-a always,exit -F arch=b32 -S open_by_handle_at -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k perm_access
\t\t\t\t-a always,exit -F arch=b32 -S open_by_handle_at -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k perm_access
\t\t\t\t-a always,exit -F arch=b64 -S open_by_handle_at -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k perm_access
\t\t\t\t-a always,exit -F arch=b64 -S open_by_handle_at -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k perm_access'.\e[0m]"
     critical=$((critical+1))
   else
           echo -e "\t\tsystem call (open_by_handle): \e[32mOk\e[0m"
     pass=$((pass+1))
   fi

   # ## V-219261 :: system call ::must generate audit records for successful/unsuccessful uses of the openat system call.
   auditdOpenat=$(auditctl -l | grep 'S openat')
   if [ -z "${auditdOpenat}" ]; then
     echo -e "\n\t\tsystem call (openat): \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mAdd '\t-a always,exit -F arch=b32 -S openat -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k perm_access
\t\t\t\t-a always,exit -F arch=b32 -S openat -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k perm_access
\t\t\t\t-a always,exit -F arch=b64 -S openat -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k perm_access
\t\t\t\t-a always,exit -F arch=b64 -S openat -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k perm_access'.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\t\tsystem call (openat): \e[32mOk\e[0m"
     pass=$((pass+1))
   fi
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
echo -e "\n\e[34m[AUDITD]\e[0m"

# ## Check.
pkgAuditd
pkgAudispd


# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"

# ## END
