#! /bin/bash
#set -x
# ## (c) 2004-2023  Cybionet - Ugly Codes Division
# ## v1.13 - November 29, 2023


# ############################################################################################
# ## SSHD

# ## Ensure permissions on /etc/ssh/sshd_config are configured.
function sshdConfPerm() {
 sshdPerm="$(ls -lah /etc/ssh/sshd_config | grep -c "\-rw-------")"

 if [ "${sshdPerm}" -eq 1 ]; then
   echo -e "\tPermission on sshd_config: \e[32mOk\e[0m (600)"
   pass=$((pass+1))
 else
   echo -e "\tPermissions on sshd_config: \e[31mCritical\e[0m\n\t\t[\e[31mEnsure permissions on /etc/ssh/sshd_config are configured to 600.\e[0m]"
   critical=$((critical+1))
 fi
}

# ## MD5 and 96-bit MAC algorithms are considered weak and have been shown to increase exploitability in SSH downgrade attacks.
function sshdMacs() {
 hmacs="$(sshd -T | grep -i 'mac' | grep -ic "hmac-md5\|hmac-md5-96")"

 if [ "${hmacs}" -le 1 ]; then
   echo -e "\n\tApproved MAC algorithms: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\n\tApproved MAC algorithms: \e[31mCritical\e[0m\n\t\t[\e[31mEnsure only approved MAC algorithms are used.\e[0m]"
   critical=$((critical+1))
 fi
}

# ## SSH warning banner should be enabled (CCE-4431-3)
function sshdBanner() {
 sshdBanner=$(grep -i 'Banner' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')
 echo -n -e "\n\tBanner: "

 if [ -z "${sshdBanner}" ]; then
   echo -e "\e[34mInformation\e[0m \n\t\t\t[\e[33mPlease consider adding \"Banner\" to SSH.\e[0m]"
   information=$((information+1))
 else
   if [ "${sshdBanner,,}" == 'none' ]; then
     echo -e "\e[34mInformation\e[0m \n\t\t\t[\e[33mPlease consider adding \"Banner\" to SSH.\e[0m]"
     information=$((information+1))
   else
     echo -e "\e[32mOk\e[0m (${sshdBanner})"
     pass=$((pass+1))
   fi
 fi
}

# ## Restricting which users can remotely access the system via SSH will help ensure that only authorized users access the system.
function sshdAccessLimited() {
  sshdLimited=$(grep -ie 'AllowUsers' -ie 'AllowGroups' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2","}' | sed -z 's/\n//g' | sed 's/,$//g')
# sshdLimited=$(grep -ie 'AllowUsers' -ie 'AllowGroups' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')

 echo -n -e "\n\tAllowed Access: "

 if [ -z "${sshdLimited}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mPlease consider adding \"AllowUsers\" or \"AllowGroups\" to SSH.\e[0m]"
   critical=$((critical+1))
 else
   echo -e "\e[32mOk\e[0m (${sshdLimited})"
   pass=$((pass+1))
 fi

}

# ## Check if the hmac-sha2-512 algorithm is suported for PowerShell script (Informal only).
function sshdPowerShell() {
 hmacsPS=$(sshd -T | grep -i 'mac' | grep -ic "hmac-sha2-512")

 if [ "${hmacsPS}" -ge 1 ]; then
   echo -e "\tSupport MAC algorithms for PowerShell: \e[32mOk\e[0m (hmac-sha2-512)"
   information=$((information+1))
 else
   echo -e "\tSupport MAC algorithms for PowerShell: \e[34mNo\e[0m (hmac-sha2-512)"
   information=$((information+1))
 fi
}

function sshdSshAudit() {
 APPDEP='ssh-audit'

 listen="$(</etc/ssh/sshd_config grep -i "^ListenAddress" | awk -F " " '{print $2}')"
 port="$(</etc/ssh/sshd_config grep -i "^port" | awk -F " " '{print $2}')"

 if  [ -z "${listen}" ] ; then
   listen='127.0.0.1'
 fi

 # ## Check if ssh-audit package is installed.
 # ## Result: 0=Installed, 1=Missing
 if ! dpkg-query -s "${APPDEP}" > /dev/null 2>&1; then
   echo -e "\n\t${APPDEP}: \e[33mWarning\e[0m"
   echo -e "\t\t[\e[33mPlease consider to install ssh-audit.\e[0m]"
   warning=$((warning+1))
 else
   sshAuditFail=$(ssh-audit -lfail -p"${port}" "${listen}" | sed '/^\s*$/d' | wc -l)
   sshAuditWarn=$(ssh-audit -lwarn -p"${port}" "${listen}" | sed '/^\s*$/d' | wc -l)

   echo -e "\n\tSsh-audit: \e[32mInstalled\e[0m"

   if [ "${sshAuditFail}" -gt 0 ]; then
     echo -e "\t\t[\e[31mRun \"ssh-audit -p${port} ${listen}\", and make correction in sshd_config.\e[0m]"
     critical=$((critical+1))
   else
     if [ "${sshAuditWarn}" -gt 0 ]; then
       echo -e "\t\t[\e[33;1;208mRun ssh-audit -p${port} ${listen}, and make correction required in sshd_config.\e[0m]"
       warning=$((warning+1))
     else
       echo -e "\t\t[\e[33mRun \"ssh-audit -p${port} ${listen}\", and make correction in sshd_config if needed.\e[0m]"
       pass=$((pass+1))
     fi
   fi
 fi
}

# ## UNUSED
function sshdT() {
sshd -t
}

# ## Check all parameters.
function sshdParam() {
 echo -e "\n\tParameters:"

 # ## Protocol (SSH-7408)
 sshdPort="$(</etc/ssh/sshd_config grep '^Port' | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tPort: "
 if [ -z "${sshdPort}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"Port\" parameter.\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdPort}" -ne 22 ]; then
        echo -e "\e[32mOk\e[0m (${sshdPort})"
        pass=$((pass+1))
   else
        echo -e "\e[31mCritical\e[0m (${sshdPort})  \n\t\t\t[\e[31mConsider hardening the SSH configuration by changing the listening port parameter.\e[0m]"
        critical=$((critical+1))
   fi
 fi

 # ## Protocol (V-219308)(CCE-4325-7)
 sshdProtocol="$(</etc/ssh/sshd_config grep 'Protocol' | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tProtocol: "

 if [ -z "${sshdProtocol}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"Protocol\" parameter.\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdProtocol}" -eq 2 ]; then
     echo -e "\e[32mOk\e[0m (${sshdProtocol})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdProtocol})  \n\t\t\t[\e[31mMake sure to assign the value \"2\" to the \"Protocol\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

 # ## PermitRootLogin (CCE-4387-7)
 sshdPermRoot="$(</etc/ssh/sshd_config grep 'PermitRootLogin' | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tPermitRootLogin: "

 if [ -z "${sshdPermRoot}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"PermitRootLogin\" parameter.\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdPermRoot,,}" == 'no' ]; then
     echo -e "\e[32mOk\e[0m (${sshdPermRoot})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdPermRoot})  \n\t\t\t[\e[31mMake sure to assign the value \"No\" to the \"PermitRootLogin\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

 # ## Operating system must be configured so that remote X connections are disabled (V-238219).
 # ## The security risk of using X11 forwarding is that the client's X11 display server may be exposed to attack when the SSH client requests forwarding.
 sshX11Forw="$(grep -i 'x11Forwarding' /etc/ssh/sshd_config | grep -v "^#" | awk -F " " '{print $2}')"
 echo -n -e "\t\tX11Forwarding: "

 if [ -z "${sshX11Forw}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"X11Forwarding\" parameter.\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshX11Forw,,}" == 'no' ]; then
     echo -e "\e[32mOk\e[0m (${sshX11Forw})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshX11Forw}) \n\t\t\t[\e[31mMake sure to assign the value \"No\" to the \"X11Forwarding\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

# ## Ensure SSH LoginGraceTime is set to one minute or less (V-25274).
# ## Setting the `LoginGraceTime` parameter to a low number will minimize the risk of successful brute force attacks to the SSH server.
 sshdLoginGrace="$(grep -i 'LoginGraceTime' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tLoginGraceTime: "

 if [ -z "${sshdLoginGrace}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"LoginGraceTime\" parameter to 60 seconds (1 minute).\e[0m]"
   critical=$((critical+1))
 else
   if [[ "${sshdLoginGrace}" == '60'  ||  "${sshdLoginGrace}" == '1m' ]]; then
     echo -e "\e[32mOk\e[0m (${sshdLoginGrace})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdLoginGrace}) \n\t\t\t[\e[31mMake sure to assign the value \"1m\" or \"60\" to the \"LoginGraceTime\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

# ## SSH must be configured and managed to meet best practices (CCE-4030-3).
# ## Setting the `IgnoreRhosts` parameter to minimize the risk that an attacker could use flaws in the Rhosts protocol to gain acces.
 sshdIgnoreRhosts="$(grep -i 'IgnoreRhosts' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tIgnoreRhosts: "

 if [ -z "${sshdIgnoreRhosts}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"IgnoreRhosts\" parameter to \"Yes\".\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdIgnoreRhosts,,}" == 'yes' ]; then
     echo -e "\e[32mOk\e[0m (${sshdIgnoreRhosts})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdIgnoreRhosts}) \n\t\t\t[\e[31mMake sure to assign the value \"Yes\" to the \"IgnoreRhosts\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

# ## Ensure SSH Idle Timeout Interval is configured.
# ## Having no timeout value associated with a connection could allow an unauthorized user access to another user's ssh session.
 # ## ClientAliveCountMax ()
 sshdCltAlive="$( grep -i 'ClientAliveCountMax' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tClientAliveCountMax: "

 if [ -z "${sshdCltAlive}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"ClientAliveCountMax\" parameter to \"1\".\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdCltAlive}" -eq 1 ]; then
     echo -e "\e[32mOk\e[0m (${sshdCltAlive})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdCltAlive}) \n\t\t\t[\e[31mMake sure to assign the value \"1\" to the \"ClientAliveCountMax\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

 # ## Operating system must not allow unattended or automatic login via SSH (V-238218)(CCE-3660-8).
 # ## Failure to restrict system access to authenticated users negatively impacts Ubuntu operating system security. 
 sshdPermPass="$(grep -i 'PermitEmptyPasswords' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tPermitEmptyPasswords: "

 if [ -z "${sshdPermPass}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"PermitEmptyPasswords\" parameter.\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdPermPass,,}" == 'no' ]; then
     echo -e "\e[32mOk\e[0m (${sshdPermPass})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdPermPass}) \n\t\t\t[\e[31mMake sure to assign the value \"no\" to the \"PermitEmptyPasswords\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

# ## Ensure SSH MaxAuthTries is set to 6 or less.
 sshdMaxAuthTries=$(grep -i 'MaxAuthTries' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')
 echo -n -e "\t\tMaxAuthTries: "

 if [ -z "${sshdMaxAuthTries}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mEnsure SSH \"MaxAuthTries\" parameter is set to 6 or less.\e[0m]"
   critical=$((critical+1))
 else
   if [[ "${sshdMaxAuthTries}" -le 6 ]]; then
     echo -e "\e[32mOk\e[0m (${sshdMaxAuthTries})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdMaxAuthTries}) \n\t\t\t[\e[31mSetting the \"MaxAuthTries\" parameter to a low number will minimize the risk of successful brute force attacks to the SSH server. While the recommended setting is 4.\e[0m]"
     critical=$((critical+1))
   fi
 fi

# ## Ensure SSH Idle Timeout Interval is configured.
 sshdClientAliveInterval="$(grep -i 'ClientAliveInterval' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tClientAliveInterval: "

 if [ -z "${sshdClientAliveInterval}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mEnsure SSH \"ClientAliveInterval\" parameter is set to \"600\" or less.\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdClientAliveInterval}" -le 600 ]; then
     echo -e "\e[32mOk\e[0m (${sshdClientAliveInterval})"
     pass=$((pass+1))
   else
     if [ "${sshdClientAliveInterval}" -gt 600 ]; then
       echo -e "\e[32mOk\e[0m (${sshdClientAliveInterval}) \n\t\t\t[\e[33mSetting the \"ClientAliveInterval\" parameter to \"600\" or less.\e[0m]"
       pass=$((pass+1))
     else
       echo -e "\e[31mCritical\e[0m (${sshdClientAliveInterval}) \n\t\t\t[\e[31mSetting the \"ClientAliveInterval\" parameter to \"600\" or less.\e[0m]"
       critical=$((critical+1))
     fi
   fi
 fi

# ## Users are not allowed to set environment options for SSH. An attacker may be able to bypass some access restrictions over SSH.
# ## [Microsoft CCE-14716-5]
 sshdPermitUserEnvironment="$(grep -i 'PermitUserEnvironment' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tPermitUserEnvironment: "

 if [ -z "${sshdPermitUserEnvironment}" ]; then
   echo -e "\e[33mWarning\e[0m \n\t\t\t[\e[33mPlease consider to set SSH \"PermitUserEnvironment\" parameter to \"No\".\e[0m]"
   warning=$((warning+1))
 else
   if [ "${sshdPermitUserEnvironment,,}" == 'no' ]; then
     echo -e "\e[32mOk\e[0m (${sshdPermitUserEnvironment})"
     pass=$((pass+1))
   else
     echo -e "\e[33mWarning\e[0m (${sshdPermitUserEnvironment}) \n\t\t\t[\e[33mSetting the \"PermitUserEnvironment\" parameter to \"No\".\e[0m]"
     warning=$((warning+1))
   fi
 fi

# ## SSH host-based authentication should be disabled.
# ## [Microsoft CCE-4370-3]
 sshdHostbasedAuthentication="$(grep -i 'HostbasedAuthentication' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
 echo -n -e "\t\tHostbasedAuthentication: "

 if [ -z "${sshdHostbasedAuthentication}" ]; then
   echo -e "\e[33mWarning\e[0m \n\t\t\t[\e[33mPlease consider to set SSH \"HostbasedAuthentication\" parameter to \"No\".\e[0m]"
   warning=$((warning+1))
 else
   if [ "${sshdHostbasedAuthentication,,}" == 'no' ]; then
     echo -e "\e[32mOk\e[0m (${sshdHostbasedAuthentication})"
     pass=$((pass+1))
   else
     echo -e "\e[33mWarning\e[0m (${sshdHostbasedAuthentication}) \n\t\t\t[\e[33mSetting the \"HostbasedAuthentication\" parameter to \"No\".\e[0m]"
     warning=$((warning+1))
   fi
 fi

# ## Depreciated
# ## Emulation of the rsh command through the ssh server should be disabled. An attacker could use flaws in the RHosts protocol to gain access.
# ## CCE-4475-0
# sshdRhostsRSAAuthentication="$(grep -i 'RhostsRSAAuthentication' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')"
# echo -n -e "\t\tRhostsRSAAuthentication: "
#
# if [ -z "${sshdRhostsRSAAuthentication}" ]; then
#   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mPlease consider to set SSH \"RhostsRSAAuthentication\" parameter to \"No\".\e[0m]"
#   critical=$((critical+1))
# else
#   if [ "${sshdRhostsRSAAuthentication,,}" == 'no' ]; then
#     echo -e "\e[32mOk\e[0m (${sshdRhostsRSAAuthentication})"
#     pass=$((pass+1))
#   else
#     echo -e "\e[31mCritical\e[0m (${sshdRhostsRSAAuthentication}) \n\t\t\t[\e[31mCritical the \"RhostsRSAAuthentication\" parameter to \"No\".\e[0m]"
#     critical=$((critical+1))
#   fi
# fi

 # ## Compression [Cisofy SSH-7408]
 sshdCompression=$(grep -i 'Compression' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')
 echo -n -e "\t\tCompression: "

 if [ -z "${sshdCompression}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"Compression\" parameter to \"No\".\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdCompression,,}" == 'no' ]; then
     echo -e "\e[32mOk\e[0m (${sshdCompression})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdCompression}) \n\t\t\t[\e[31mMake sure to assign the value \"No\" to the \"Compression\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi

 # ## GatewayPorts [Stig V-63213]
 sshdGwPorts=$(grep -i 'GatewayPorts' /etc/ssh/sshd_config | grep -v '^#' | awk -F " " '{print $2}')
 echo -n -e "\t\tGatewayPorts: "

 if [ -z "${sshdGwPorts}" ]; then
   echo -e "\e[31mCritical\e[0m \n\t\t\t[\e[31mMake sure to set the \"No\" parameter.\e[0m]"
   critical=$((critical+1))
 else
   if [ "${sshdGwPorts,,}" == 'no' ]; then
     echo -e "\e[32mOk\e[0m (${sshdGwPorts})"
     pass=$((pass+1))
   else
     echo -e "\e[31mCritical\e[0m (${sshdGwPorts}) \n\t\t\t[\e[31mMake sure to assign the value \"No\" to the \"GatewayPorts\" parameter.\e[0m]"
     critical=$((critical+1))
   fi
 fi
}

function sshd2fa(){
 sshdMfa=$(</etc/pam.d/sshd grep 'pam_google_authenticator.so' | grep -c -v '#')
 echo -n -e "\n\tGoogle Authenticator: "

 if [[ "${sshdMfa}" -eq 0 ]]; then
   # ## apt-get install libpam-google-authenticator
   echo -e "\e[33mWarning\e[0m \n\t\t\t[\e[33mPlease consider using MFA with libpam-google-authenticator on the SSHD service.\e[0m]"
   warning=$((warning+1))
 else
   if [[ "${sshdMfa}" -eq 1 ]]; then
     echo -e "\e[32mOk\e[0m"
     pass=$((pass+1))
   else
     # ## apt-get install libpam-google-authenticator
     echo -e "\e[33mWarning\e[0m \n\t\t\t[\e[33mPlease consider using MFA on the SSHD service.\e[0m]"
     warning=$((warning+1))
   fi
 fi
}

# ## Checks for the presence of the package.
function checkAutoSSH() {
 REQUIRED_PKG="${1}"
 if dpkg-query -s "autossh" > /dev/null 2>&1; then
   isRunning="$(ps -e | grep -c autossh)"

   if [ "${isRunning}" -gt 0 ];then
     echo -e "\n\tAutossh: \e[31mCritical\e[0m"
     echo -e "\t\t\t[\e[31mPlease consider to uninstall autossh, it is not used. If the package is already uninstalled, use the 'dpkg -P autossh' command.\e[0m]"
     critical=$((critical+1))
   else
     echo -e "\n\tAutossh: \e[33mWarning\e[0m"
     echo -e "\t\t[\e[33;1;208mPlease consider to uninstall autossh if you don't use it.\e[0m]"
     warning=$((warning+1))
   fi
 fi
}


#function checkPackage() {
# REQUIRED_PKG="${1}"
#
# if ! dpkg-query -s "${REQUIRED_PKG}" > /dev/null 2>&1; then
#   dependency='0'
# else
#   dependency='1'
# fi
#}


# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\e[34m[SSHD]\e[0m"

# ## Check.
sshdConfPerm
sshdAccessLimited
sshd2fa
sshdParam
sshdBanner
sshdMacs
sshdPowerShell
checkAutoSSH

# ## ssh-audit
sshdSshAudit

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"


# ## END
