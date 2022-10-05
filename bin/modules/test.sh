#! /bin/bash


function repoCronPerm() {
 # ## Sub-Header.
 echo -e '\n\tCron Repositories:'
 cronrepo=( "hourly" "daily" "weekly" "monthly" "d" )

 for crons in "${cronrepo[@]}"
 do
   cronPerm="$(ls -lah /etc/cron.${crons} | grep -c "drw-------")"

   if [ "${cronPerm}" -eq 1 ]; then
     echo -e "\t\tcron.${crons}: \e[32mOk\e[0m (600)"
     pass=$((pass+1))
   else
     echo -e "\t\tcron.${crons}: \e[31mCritical\e[0m\n\t\t\t[\e[31mEnsure permissions on /etc/cron.${crons} are configured to 600.\e[0m]"
     critical=$((critical+1))
   fi
 done
}



repoCronPerm

