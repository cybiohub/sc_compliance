#! /bin/bash
#set -x
# ## (c) 2004-2024  Cybionet - Ugly Codes Division
# ## v1.1 - March 30, 2024


# ## Value: empty, --ipv4 or --ipv6.
forceIpVersion='-4'

here=$(dirname "${0}")

if [ -z "${here}" ]; then
  exit 1
else
  cd "${here}"
  echo -e "\e[32mUPDATING:\e[0m Launching the update."
  git pull "${forceIpVersion}"  https://github.com/cybiohub/sc_compliance.git
fi

# ## Exit.
exit 0

# ## END
