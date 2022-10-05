#! /bin/bash
#set -x
# ## (c) 2004-2022  Cybionet - Ugly Codes Division
# ## v1.7 - September 18, 2022


# ############################################################################################
# ## IPTABLES

function iptablesCheck() {
 pInput="$(iptables -S | grep 'P INPUT' | awk -F " " $'{print $3}')"

 if [ "${pInput}" == 'DROP' ]; then
   echo -e "\tINPUT permanent rule: \e[32m${pInput}\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tINPUT permanant rule: \e[31m${pInput}\e[0m"
   critical=$((critical+1))
 fi

 pForward="$(iptables -S | grep 'P FORWARD' | awk -F " " $'{print $3}')"

 if [ "${pForward}" == 'DROP' ]; then
   echo -e "\tFORWARD permanent rule: \e[32m${pForward}\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tFORWARD permanant rule: \e[31m${pForward}\e[0m"
   critical=$((critical+1))
 fi

 pOutput="$(iptables -S | grep 'P OUTPUT' | awk -F " " $'{print $3}')"

 if [ "${pOutput}" == 'DROP' ]; then
   echo -e "\tOUTPUT permanent rule: \e[32m${pOutput}\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tOUTPUT permanant rule: \e[33m${pOutput}\e[0m"
   echo -e '\t\t[\e[33mPlease consider to set OUTPUT permanant rule to "DROP".\e[0m]'
   warning=$((warning+1))
 fi
}

function iptablesCountry() {
 geoIp="$(iptables -S | grep "\-source-country" | grep -c 'DROP')"

 if [ "${geoIp}" -eq 0 ]; then
   echo -e '\tCountry filtering: \e[31mCritical\e[0m\n\t\t[\e[31mPlease consider to install xt_geoip to filtering country.\e[0m]'
   critical=$((critical+1))
 else
   echo -e "\tCountry filtering: \e[32mOk\e[0m"
   pass=$((pass+1))
 fi
}

function iptablesIpset() {
 ipSet="$(iptables -S | grep "\-match-set" | grep -c -i 'tor')"

 if [ "${ipSet}" -eq 0 ]; then
   echo -e '\tTor exit nodes filtering: \e[33mWarning\e[0m\n\t\t[\e[33mPlease consider to add filtering "Tor exit nodes" rule with ipset.\e[0m]'
   warning=$((warning+1))
 else
   echo -e "\tTor exit nodes filtering: \e[32mOk\e[0m (empty)"
   pass=$((pass+1))
 fi
}

function inputRulesNotUsed() {
 acceptInputRNU="$(iptables -nvL INPUT | grep "0     0" | grep -v 'state' | grep -c 'ACCEPT')"

 if [ "${acceptInputRNU}" -eq 0 ]; then
   echo -e "\n\tACCEPT rules not used in the INPUT chain: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\n\tSome ACCEPT rules in the INPUT chain are not used: \e[33mWarning\e[0m (${acceptInputRNU}) \n\t\t[\e[33mPlease consider to removing these.\e[0m]"
   badInRules=$(iptables -nvL INPUT | grep "0     0" | grep -v 'state' | grep 'ACCEPT')
   echo -e "${badInRules}"

   warning=$((warning+1))
 fi
}

function outputRulesNotUsed() {
 acceptOutputRNU="$(iptables -nvL OUTPUT | grep "0     0" | grep -v 'state' | grep -c 'ACCEPT')"

 if [ "${acceptOutputRNU}" -eq 0 ]; then
   echo -e "\n\tACCEPT rules not used in the OUTPUT chain: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\n\tSome ACCEPT rules in the OUTPUT chain are not used: \e[33mWarning\e[0m (${acceptOutputRNU}) \n\t\t[\e[33mPlease consider to removing these.\e[0m]"
   badOutRules=$(iptables -nvL OUTPUT | grep "0     0" | grep -v 'state' | grep 'ACCEPT')
   echo -e "\t\t[${badOutRules}]"
   
   warning=$((warning+1))
 fi
}


# ############################################################################################
# ## IP6TABLES

function ipv6Enable() {
 declare -i ipv6_disabled
 ipv6_disabled="$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)"

 # Valeur possible pour disable_ipv6 : 0=actif, 1=désactivé.
 if [ "${ipv6_disabled}" -eq 1 ]; then
   echo -e "\tIPv6 Protocol: \e[34mDisabled\e[0m"
   information=$((information+1))
   # The IPv6 protocol is not enabled on this server.
 else
   ip6tablesCheck

   # ## Header.
   echo -e "\n\e[34m[IP6TABLES FILTERING]\e[0m"

   # ## Check
   ip6tablesCountry
   ip6tablesIpset

   inputRulesNotUsed6
   outputRulesNotUsed6
 fi
}

function ip6tablesCheck() {
 p6Input="$(ip6tables -S | grep 'P INPUT' | awk -F " " $'{print $3}')"

 if [ "${p6Input}" == 'DROP' ]; then
   echo -e "\tINPUT permanent rule: \e[32m${p6Input}\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tINPUT permanant rule: \e[31m${p6Input}\e[0m"
   critical=$((critical+1))
 fi

 p6Forward="$(ip6tables -S | grep 'P FORWARD' | awk -F " " $'{print $3}')"

 if [ "${p6Forward}" == 'DROP' ]; then
   echo -e "\tFORWARD permanent rule: \e[32m${p6Forward}\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tFORWARD permanant rule: \e[31m${p6Forward}\e[0m"
   critical=$((critical+1))
 fi

 p6Output="$(ip6tables -S | grep 'P OUTPUT' | awk -F " " $'{print $3}')"

 if [ "${p6Output}" == 'DROP' ]; then
   echo -e "\tOUTPUT permanent rule: \e[32m${p6Output}\e[0m"
   pass=$((pass+1))
 else
     echo -e "\tOUTPUT permanant rule: \e[33m${p6Output}\e[0m"
     echo -e '\t\t[\e[33mPlease consider to set OUTPUT permanant rule to "DROP".\e[0m]'
     warning=$((warning+1))
 fi
}

function ip6tablesCountry() {
   geoIpV6="$(ip6tables -S | grep "\-source-country" | grep -n 'DROP')"

   if [[ "${geoIpV6}" -eq 0 ]]; then
     echo -e '\tCountry filtering: \e[31mCritical\e[0m\n\t\t[\e[31mPlease consider to add country filtering for IPv6.\e[0m]'
     critical=$((critical+1))
   else
     echo -e "\tCountry filtering: \e[32mOk\e[0m"
     pass=$((pass+1))
   fi
}

function ip6tablesIpset() {
 ipSetV6="$(ip6tables -S | grep "\-match-set" | grep -c -i 'tor')"

  if [ "${ipSetV6}" -eq 0 ]; then
   echo -e '\tTor exit nodes filtering: \e[33mWarning\e[0m\n\t\t[\e[33mPlease consider to add "Tor exit nodes" filtering rule with IPv6.\e[0m]'
   warning=$((warning+1))
 else
   echo -e "\tTor exit nodes filtering: \e[32mOk\e[0m (empty)"
   pass=$((pass+1))
 fi
}

function inputRulesNotUsed6() {
 acceptInputRNU6="$(ip6tables -nvL INPUT | grep "0     0" | grep -v 'state' | grep -c 'ACCEPT')"

 if [ "${acceptInputRNU6}" -eq 0 ]; then
   echo -e "\n\tACCEPT rules not used in the INPUT chain: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\n\tSome ACCEPT rules in the INPUT chain are not used: \e[33mWarning\e[0m (${acceptInputRNU6}) \n\t\t[\e[33mPlease consider to removing these.\e[0m]"
   warning=$((warning+1))
 fi
}

function outputRulesNotUsed6() {
 acceptOutputRNU6="$(ip6tables -nvL OUTPUT | grep "0     0" | grep -v 'state' | grep -c 'ACCEPT')"

 if [ "${acceptOutputRNU6}" -eq 0 ]; then
   echo -e "\tACCEPT rules not used in the OUTPUT chain: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tSome ACCEPT rules in the OUTPUT chain are not used: \e[33mWarning\e[0m (${acceptOutputRNU6}) \n\t\t[\e[33mPlease consider to removing these.\e[0m]"
   warning=$((warning+1))
 fi
}


# ############################################################################################
# ## CROWDSEC

function pkgCrowdsec() {

 APPDEP2='crowdsec'
 checkPackage "${APPDEP2}"
 crowdsecExist="${dependency}"

 if [ "${crowdsecExist}" -eq 1 ]; then
   # ## Header.
   echo -e "\n\e[34m[CROWDSEC]\e[0m"

   echo -e "\t${APPDEP2^}: \e[32mOk\e[0m"
   pass=$((pass+1))

   pkgFail2ban
 else
   pkgFail2ban
 fi
}


# ############################################################################################
# ## FAIL2BAN

function pkgFail2ban() {
 echo -e "\n\e[34m[FAIL2BAN]\e[0m"

 APPDEP='fail2ban'
 checkPackage "${APPDEP}"
   echo -e "\t${APPDEP^}: \e[32mOk\e[0m\n"
   pass=$((pass+1))

 # ## Check if fail2ban package is installed.
 # ## Result: 0=Missing, 1=Installed
 if [ "${dependency}" -eq 0 ] && [ "${crowdsecExist}" -eq 0 ]; then
   echo -e "\t${APPDEP}: \e[31mCritical\e[0m"
   echo -e "\t\t[\e[31mPlease consider to install ${APPDEP}.\e[0m]"
   critical=$((critical+1))
 else

  # ## Check if fail2ban is running.
   if [ -f /run/fail2ban/fail2ban.pid ]; then
     f2bFilters
   else
     echo -e "\t${APPDEP}: \e[31mCritical\e[0m"
     echo -e "\t\t[\e[31m${APPDEP^} is not running.\e[0m]"
     critical=$((critical+1))
   fi
 fi
}


function f2bFilters() {
 #declare -r wantedFilters='ssh,sshd,sshd-authfail,sshd-ddos,sshd-deny,sshd-proto'
 declare -a allFilters=($(fail2ban-client status | grep "Jail list" | grep -E -o "([-[:alnum:]]*, )*[-[:alnum:]]*$" | sed 's/,//g'))

 # ########################
 # ## SSH
 # ##

 echo -e "\tSSH: "

 # ## Now loop through the above array.
 for i in "${allFilters[@]}"
 do
   if [[ "${i}" == "ssh"* ]]; then
     echo -e -n "\t\t- ${i}\n"
   fi
 done

  # ########################
  # ## NAMED
  # ##

 echo -e "\tNAMED: "

 # ## Now loop through the above array.
 for i in "${allFilters[@]}"
 do
   if [[ "${i}" == "named"* ]]; then
     echo -e -n "\t\t- ${i}\n"
   fi
 done

 # ########################
 # ## RECIDIVE
 # ##

 echo -e "\tRECIDIVE: "

 # ## Now loop through the above array.
 for i in "${allFilters[@]}"
 do
   if [[ "${i}" == *"recidiv"* ]]; then
     echo -e -n "\t\t- ${i}\n"
   fi
 done

 # ########################
 # ## OTHERS
 # ##
 echo -e "\tOTHERS: "

 # ## Now loop through the above array.
 for i in "${allFilters[@]}"
 do
   if ! [[ "${i}" == "ssh"* || "${i}" == "named"* || "${i}" == *"recidi"* ]]; then
     echo -e -n "\t\t- ${i}\n"
   fi
 done
}


# ############################################################################################
# ## GENERAL

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
echo -e "\n\e[34m[IPTABLES]\e[0m"

# ## Check.
iptablesCheck
inputRulesNotUsed
outputRulesNotUsed

# ## Header.
echo -e "\n\e[34m[IPTABLES FILTERING]\e[0m"

# ## Check.
iptablesCountry
iptablesIpset

# ## Header and Check if IPv6 enabled.
echo -e "\n\e[34m[IP6TABLES]\e[0m"
ipv6Enable

# ## Check Crowdsec and/or Fail2ban.
pkgCrowdsec

# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"


# ## END
