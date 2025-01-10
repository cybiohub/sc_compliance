#! /bin/bash
#set -x
# ## (c) 2004-2025  Cybionet - Ugly Codes Division
# ## v1.1 - December 23, 2025


# ############################################################################################
# ## SYSCTL

# ## Performing source validation by reverse path should be enabled for all interfaces.
# ## [CCE-3840-6]
function rpFilterDefault() {
 rpFilterD="$(cat /proc/sys/net/ipv4/conf/default/rp_filter)"

 if [ "${rpFilterD}" -eq 1 ]; then
   echo -e "\tRP_Filter Default: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tRP_Filter Default: \e[31mCritical\e[0m\n\t\t[\e[31mSet 'net.ipv4.conf.default.rp_filter' to '1' in /etc/sysctl.conf file).\e[0m]"
   critical=$((critical+1))
 fi
}

# ## Performing source validation by reverse path should be enabled for all interfaces.
# ## [CCE-3840-8]
function rpFilterAll() {
 rpFilterD="$(cat /proc/sys/net/ipv4/conf/all/rp_filter)"

 if [ "${rpFilterD}" -eq 1 ]; then
   echo -e "\tRP_Filter All: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tRP_Filter All: \e[31mCritical\e[0m\n\t\t[\e[31mSet 'net.ipv4.conf.all.rp_filter' to '1' in /etc/sysctl.conf file).\e[0m]"
   critical=$((critical+1))
 fi
}

# ## The default setting for accepting source routed packets should be disabled for network interfaces.
# ## [CCE-4091-5]
function acceptSourceRouteDefault() {
 asrDefault="$(cat /proc/sys/net/ipv4/conf/default/accept_source_route)"

 if [ "${asrDefault}" -eq 0 ]; then
   echo -e "\tAccept_Source_route Default: \e[32mOk\e[0m"
   pass=$((pass+1))
 else
   echo -e "\tAccept_Source_Route Default: \e[31mCritical\e[0m\n\t\t[\e[31mSet 'net.ipv4.conf.default.accept_source_route' to '0' in /etc/sysctl.conf file).\e[0m]"
   critical=$((critical+1))
 fi
}


# ############################################################################################
# ## EXECUTION

# ## Header.
echo -e "\n\n\e[34m[NETWORKING]\e[0m"

rpFilterDefault
rpFilterAll
acceptSourceRouteDefault


# ## Return status.
return "${pass}"
return "${warning}"
return "${critical}"
return "${information}"


# ## END
