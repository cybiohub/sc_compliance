#! /bin/bash
#set -x
# ## (c) 2004-2022  Cybionet - Ugly Codes Division
# ## v0.1 - January 18, 2022

# REF.: https://ubuntu.com/server/docs/security-apparmor


# ############################################################################################
# ## APPARMOR

# ## 1) Vérifier si apparmor installé

# ## 2)2)  Vérifier si apparmor-utils est installé
# ## apparmor-utils - utilities for controlling AppArmor   ex.: aa-unconfined
#apt-get install apparmor-utils


# ## AppArmor return nothing if enabled.
#apparmor_status
aa-status --enabled


# ## The -Z parameter to the ps commande can be used to list processes that are secured by ArpArmor.
# ## Example:
# ## /usr/sbin/slapd (enforce)       openldap     835       1  0 Jan05 ?        00:00:13 /usr/sbin/slapd -h ldap:/// ldapi:/// -g openldap -u openldap -F /etc/ldap/slapd.d
# ## /usr/sbin/named (enforce)       bind     1497697       1  0 Jan13 ?        00:00:59 /usr/sbin/named -4 -f -u bind -t /var/chroot/bind
ps -efZ | grep -v unconfined
