# VPS-Recon
## Changing source lists
> Switch to root!
```
sudo su


/etc/sources.list

deb http://kali.cs.nctu.edu.tw/kali kali-rolling main contrib non-free
# For source package access, uncomment the following line
# deb-src http://kali.cs.nctu.edu.tw/kali kali-rolling main contrib non-free

# download
wget http://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2022.1_all.deb
# install
sudo dpkg -i kali-archive-keyring_2022.1_all.deb
# remove downloaded file again
rm kali-archive-keyring_2022.1_all.deb
# update
sudo apt-get update

#sublist3r
sudo apt install sublist3r

#nmap
sudo apt install nmap

