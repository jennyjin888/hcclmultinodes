#! /bin/bash
##upgrade related driver
#bash habana_ins.sh
sudo wget -nv https://vault.habana.ai/artifactory/gaudi-installer/1.13.0/habanalabs-installer.sh
sudo chmod +x habanalabs-installer.sh
sleep 5
./habanalabs-installer.sh install --type base
echo "Waiting for installation to complete"

./habanalabs-installer.sh install -t dependencies

echo "Waiting for installation dependencies to complete"



##Reload driver
echo "Reload Habana Drivers"
sudo modprobe habanalabs_en
sudo modprobe habanalabs
sleep 10

echo "Check each OAM SPI firmware"
hl-smi -q | grep -i SPI
