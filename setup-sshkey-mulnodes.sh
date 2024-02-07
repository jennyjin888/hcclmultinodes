#! /bin/bash
ssh-keygen -q -t rsa -N '' <<< $'\ny'
myownip=`ip a | grep ens93f1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'  | head -n 1`
echo "===My System IP Address=== : $myownip"
while read arg; do
  if [[ $myownip != $arg ]]; then 
    echo "Pair System IP Address: $arg"
    ssh-copy-id smc@$arg
  fi
done

