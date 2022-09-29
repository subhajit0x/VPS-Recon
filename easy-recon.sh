#!/usr/bin/bash

echo "Enter your Target - >"

read DomainName

mkdir autorecon-recon-results
cd ~/autorecon-recon-results/
pwd
sleep 2

subfinder -d $DomainName -silent | httpx -silent | nuclei -t ../nuclei-templates/ -o nuclei-subs.txt


echo $DomainName | subfinder -silent | httpx -silent | hakrawler > hakrawler-subs.txt

sleep 2

amass enum -passive -norecursive -noalts -d $DomainName -o amass-results.txt
assetfinder $DomainName | httprobe > assetfinder-live.txt
#add more tools to get all subdomains

cat *.txt | sort -u > all.txt 

sleep 2
echo " CHECKING LIVE DOMAINS >>>>>"
cat all.txt | httpx -o live-subs.txt
sleep 2


#snap install feroxbuster
# ln /path/to/the/wordlist ~/snap/feroxbuster/common or cp /path/to/the/wordlist ~/snap/feroxbuster/common

cat live-subs.txt | feroxbuster --stdin -e -w /snap/feroxbuster/common | tee feroxbuster.txt
