#!/bin/bash

echo "Enter your Target - >"

read DomainName

mkdir -p $DomainName
cd $DomainName
echo "Starting recon on $DomainName"

# Subdomain enumeration
echo "Running Subfinder"
subfinder -d $DomainName -o subdomains.txt
sleep 10;

# Subdomain enumeration with crt.sh
echo "========== Fetching Subdomains from crt.sh =========="
curl -s "https://crt.sh/?q=%25.$DomainName&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a subdomains.txt && echo "[+] crt.sh fetch completed."
sleep 5

echo "Running Httpx"
httpx -l subdomains.txt  -o httpx.txt
echo " "
echo "============== subdomains.txt & httpx.txt saved & done ================="
sleep 10
# Shodan scans
echo "================ Shodan Scan ============="
shodan init 3GX1LChUx5PBe9PeYMTFyFiOH42u2aeV

shodan domain $DomainName > shodan.txt

sleep 5;
echo "=================== Shodan Scan Done =================="
# Asset Discovery
echo "=========== Assetfider Scan running ================"
assetfinder --subs-only $DomainName | tee -a assetfinder.txt
echo "============== Assetfinder Scan Done =============="
sleep 5;
# Amass for DNS Enumeration
echo "============== Amass Scan running ================"
amass enum -d $DomainName -o amass.txt
echo "=============== Amass Scan Done ================="
sleep 3
echo "================ Waybackurls Starting ================"
echo $DomainName | waybackurls | tee -a waybackurls.txt
echo "=============== Waybackurls Scan Done ================="
# Gather Javascript Files
cat httpx.txt | getJS --complete | tee -a jsfiles.txt
sleep 3;
# Directory bruteforcing with GoBuster
gobuster dir -u https://$DomainName -w /Users/subhajit/Desktop/recon/SecLists/Discovery/Web-Content/common.txt -b 301 -o gobuster.txt
sleep 10;
# Use hakrawler for crawling 
echo $DomainName | hakrawler | tee -a hakrawler.txt

# Use Nuclei for template-based scanning
nuclei -l httpx.txt -t /Users/subhajit/Desktop/recon/nuclei-templates -o nuclei.txt
cat *.txt | sort -u > all.txt 

# Use Arjun to discover hidden HTTP parameters
arjun -i httpx.txt --stable -oT arjun.txt 
sleep 10;
# Cleanup duplicates
sort -u all.txt -o all.txt

echo "Recon on $DomainName finished"
