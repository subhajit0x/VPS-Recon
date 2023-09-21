#!/bin/bash
STATE_FILE="state.log"




echo "Enter your Target ->"
read DomainName

mkdir -p "$DomainName"
cd "$DomainName"
echo "Starting recon on $DomainName"


# Subdomain enumeration

echo "Running Subfinder"
subfinder -d "$DomainName" -o subdomains.txt &
subfinder_pid=$!

# Subdomain enumeration with crt.sh

echo "========== Fetching Subdomains from crt.sh =========="
# Fetch and filter the subdomains from crt.sh
curl -s "https://crt.sh/?q=%25.$DomainName&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > crtsh_subdomains.txt

# Wait for both subfinder and crt.sh to finish
wait $subfinder_pid
wait $crtsh_pid

echo "Running Httpx"
httpx -l subdomains.txt -o httpx.txt
echo " "
echo "============== subdomains.txt & httpx.txt saved & done ================="


# Shodan scans
echo "================ Shodan Scan ============="
shodan init 3GX1LChUx5PBe9PeYMTFyFiOH42u2aeV
shodan domain "$DomainName" > shodan.txt &
shodan_pid=$!
echo "=================== Shodan Scan Done =================="

# Asset Discovery
echo "=========== Assetfinder Scan running ================"
assetfinder --subs-only "$DomainName" | tee -a assetfinder.txt &
assetfinder_pid=$!

echo "============== Assetfinder Scan Done =============="

# Amass for DNS Enumeration
echo "============== Amass Scan running ================"
amass enum -passive -d $DomainName -o amass.txt
echo "=============== Amass Scan Done =================" &
amass_pid=$!

sleep 3

echo "================ Waybackurls Starting ================"
echo "$DomainName" | waybackurls | tee -a waybackurls.txt &
waybackurls_pid=$!

echo "=============== Waybackurls Scan Done ================="

# Gather JavaScript Files using getJS
echo "Gathering JavaScript Files..."
cat httpx.txt | getJS --complete > jsfiles.txt

# Record the start time for checking JavaScript files for URLs
start_js_check_time=$(date +%s)

# Define a function to process JavaScript files
process_js_file() {
    local jsfile="$1"
    local output_file="jsfile-urls-$$.txt" # Use a unique file for each process
    echo "Processing: $jsfile"
    
    # Record the start time for each file
    file_start_time=$(date +%s)
    
    # Use curl to fetch the JavaScript file and extract URLs
    curl "$jsfile" | grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*" > "$output_file"
    
    # Record the end time for each file
    file_end_time=$(date +%s)
    file_duration=$((file_end_time - file_start_time))
    
    # Append the result to the main URLs file
    cat "$output_file" >> jsfile-urls.txt
    
    # Remove the temporary output file
    rm "$output_file"
    
    echo "Processing time for $jsfile: $file_duration seconds"
}

# Export the function to make it available to xargs
export -f process_js_file

# Get the number of available CPU cores
num_cores=$(nproc)

# Use xargs to process JavaScript files in parallel, utilizing all available CPU cores
cat jsfiles.txt | xargs -P "$num_cores" -n 1 -I {} bash -c 'process_js_file "{}"'

# Record the end time for checking JavaScript files for URLs
end_js_check_time=$(date +%s)
js_check_duration=$((end_js_check_time - start_js_check_time))
echo "JavaScript file checking completed in $js_check_duration seconds."

echo "================ Gobuster Starting ================"
gobuster dir -u "https://$DomainName" -w /home/subh/SecLists/Discovery/Web-Content/common.txt -b 301 -o gobuster.txt &
gobuster_pid=$!
echo "================ Gobuster Done ================"
sleep 10

# Use hakrawler for crawling 
fullURL="http://$DomainName"

echo "$fullURL" | hakrawler | tee -a hakrawler.txt &
hakrawler_pid=$!

# Use Nuclei for template-based scanning
nuclei -l httpx.txt -t /home/subh/nuclei-templates -o nuclei.txt &
nuclei_pid=$!

wait $shodan_pid
wait $assetfinder_pid
wait $amass_pid
wait $waybackurls_pid
wait $jsfiles_pid
wait $gobuster_pid
wait $hakrawler_pid
wait $nuclei_pid

# Use parallel for Heartbleed check
echo "Checking for Heartbleed vulnerability"
parallel --jobs 10 "timeout 5 echo 'QUIT' | openssl s_client -connect {}:443 2>&1 | grep 'server extension \"heartbeat\" (id=15)' || echo '{}: safe'" :::: subdomains.txt > heartbleed-test.txt

# Assuming the smuggler.py tool is in the specified path
smuggler_script="/home/subh/Desktop/bb-tools/smuggler/smuggler.py"

# Check for HTTP Smuggling in parallel with a timeout of 10 seconds for each test
echo "Checking for HTTP Smuggling vulnerability"
cat subdomains.txt | parallel --jobs 10 "timeout 10 python3 $smuggler_script -u 'http://{}' | tee -a http-smuggling-test.txt"

echo "HTTP Smuggling check completed."


# Use githound to search for sensitive information in GitHub repositories
#echo "$DomainName" | git-hound --dig-files --dig-commits --many-results --languages common-languages.txt --threads 100 > githound-results.txt

# Cleanup duplicates
cat *.txt | sort -u > all.txt

echo "=============== Sniper Scan Started on subdomains ================="
parallel --jobs 10 "sniper -t {} -m nuke -w $DomainName" :::: subdomains.txt
echo "=============== Sniper Scan Done ================="
echo "=========== Sn1per results copying into current dir"
cp -r /usr/share/sn1per/loot/workspace/"$DomainName" .
echo "=========== Sn1per results copying into current dir done"

echo "Recon on $DomainName finished"

#echo "Converting all.txt to PDF..."
#pandoc all.txt -o all.pdf
#echo "PDF has been saved to the current folder as all.pdf"

echo "Sending PDF to Discord webhook..."
curl -X POST -F "file=@all.txt" "https://discordapp.com/api/webhooks/1151537787619786823/ehrjxQaRXi2giZtRoiupcSw_wSpUmC5Z9V_09bxtB-andOkyQ9-AemuuYWH9w5Y4zCl6"
echo "PDF sent to Discord successfully!"
