#! /bin/bash
#set -x
# ## (c) 2004-2021  Cybionet - Ugly Codes Division
# ## v1.0 - September 25, 2021


# ############################################################################################
# ## APACHE2

CSR
# ## Vérifie si le module est chargé dans Apache2.
apachectl -M 2>&1 | grep security

vim /etc/apache2/conf-available/security.conf
  ServerTokens Prod
  ServerSignature o

# ## Timezone.
timezone='America\/Montreal'

CHANGER le parametre 'AllowOverride' de 'None' a 'ALL' dans le repertoire /var/www/ du fichier apache2.conf

# ## END
