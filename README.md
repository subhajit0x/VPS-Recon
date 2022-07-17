# VPS-Recon
> Changing source lists
```
sudo nano /etc/sources.list

> Adding Kali mirror
deb http://kali.cs.nctu.edu.tw/kali kali-rolling main contrib non-free
# For source package access, uncomment the following line
# deb-src http://kali.cs.nctu.edu.tw/kali kali-rolling main contrib non-free

> Adding in keyring
# download
wget http://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2022.1_all.deb
# install
sudo dpkg -i kali-archive-keyring_2022.1_all.deb
# remove downloaded file again
rm kali-archive-keyring_2022.1_all.deb
# update
sudo apt-get update

> Adding tools
#sublist3r
sudo apt install sublist3r

#nmap
sudo apt install nmap

#reconFTW
git clone https://github.com/six2dez/reconftw
cd reconftw/
./install.sh
./reconftw.sh -d target.com -r

> Go env setup
# adding GO env
whichis go
sudo nano ~/.bashrc
# Golang vars
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH

#Install Subfinder
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
change ~/.config/provider-config.yaml
echo hackerone.com | subfinder -silent | httpx -silent | hakrawler > subfind.txt

#Install Assetfinder
go get -u github.com/tomnomnom/assetfinder

#gobuster
sudo apt install gobuster

#dirsearch
sudo apt install dirsearch

#hakrawler
go install github.com/hakluke/hakrawler@latest


#Commix
sudo apt install commix


#rengine
git clone https://github.com/yogeshojha/rengine && cd rengine
Change .env file 




