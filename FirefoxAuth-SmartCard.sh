#!/bin/bash
#Written by Tom Burgin | NIMH | burgintj@nimh.nih.gov
#run with sudo
#This script will enable kerberos pass through to all nih.gov websites in firefox.
#This script installs both cert chains, Entrust and Betrust into Firefox profiles for any user on the system.
#This script also enables pkcs11 for PIV authentication in Firefox on 10.6 systems

#Install Firefox nss_tools
sudo rm -rf /opt/local/lib/nss_tools/
sudo rm -rf /opt/local/lib/nss/
sudo rm -rf /opt/local/lib/nspr/
sudo mkdir -p /opt/local/lib/
sudo unzip /private/var/tmp/firefoxpiv/nss_tools.zip -d /opt/local/lib/
sudo unzip /private/var/tmp/firefoxpiv/nss.zip -d /opt/local/lib/
sudo unzip /private/var/tmp/firefoxpiv/nspr.zip -d /opt/local/lib/
sudo rm -rf /opt/local/lib/__MACOSX

globalSettings(){

domain="nih.gov" ## Set your Kerberos Domain

if grep 'network.negotiate-auth.trusted-uris' /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js;
then
	sudo sed '/network.negotiate-auth.trusted-uris/d' /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js > /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js.e;
	echo 'pref("network.negotiate-auth.trusted-uris", "$domain");' >> /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js.e;
	mv /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js.e /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js
	echo "GLOBAL: network.negotiate-auth.trusted-uris is now set to $domain using SED"
else
    echo 'pref("network.negotiate-auth.trusted-uris", "$domain");' >> /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js;
    	echo "GLOBAL: network.negotiate-auth.trusted-uris is now set to $domain"

fi

}


userSettings(){

#Get an array of all users
declare -a userarray
userarray=( `sudo ls /var/db/dslocal/nodes/Default/users/ | cut -d "." -f1` )

#Iterate through the  array of all users
for i in ${userarray[@]};
do
	if [ -d /Users/$i/Library/Application\ Support/Firefox/Profiles ];
		then
			#Get an array of all profiles under this User for Firefox
			declare -a profileArray
			profileArray=( `ls /Users/$i/Library/Application\ Support/Firefox/Profiles | grep -v DS_Store | grep -v user.js` )
			for p in ${profileArray[@]};
				do
					#PIV
					if (( `sw_vers -productVersion | cut -d "." -f2` > 6 )); 
						then 
							echo "[+] Machine is 10.7 and above - Only Adding NIH CERTS";
							for c in `ls /private/var/tmp/firefoxpiv/NIH_CERTS/`;
								do
									echo "Adding [$c] to the cert chain"
									sudo /opt/local/lib/nss_tools/certutil -d /Users/$i/Library/Application\ Support/Firefox/Profiles/$p -A -i "/private/var/tmp/firefoxpiv/NIH_CERTS/$c" -n "$c" -t "CT,C,C";
								done
						else
							echo "[+] Machine is 10.6 or below - Adding NIH CERTS and PIV Support";
							for c in `ls /private/var/tmp/firefoxpiv/NIH_CERTS/`;
								do
									echo "Adding [$c] to the cert chain"
									sudo /opt/local/lib/nss/nss-certutil -d /Users/$i/Library/Application\ Support/Firefox/Profiles/$p -A -i "/private/var/tmp/firefoxpiv/NIH_CERTS/$c" -n "$c" -t "CT,C,C";
								done
							sudo /opt/local/lib/nss/nss-modutil -dbdir /Users/$i/Library/Application\ Support/Firefox/Profiles/$p -add "OS X 10.6 PKCS11 shim" -libfile /usr/libexec/SmartCardServices/pkcs11/tokendPKCS11.so -force
							sudo echo 'user_pref("security.ssl.renego_unrestricted_hosts", "certlogin.$domain");' >> /Users/$i/Library/Application\ Support/Firefox/Profiles/user.js
							sudo echo 'user_pref("security.ssl.renego_unrestricted_hosts", "certlogin.$domain");' >> /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/user.js
					fi

					#Kerberos
					if grep 'network.negotiate-auth.trusted-uris' /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js;
					then
						sudo sed '/network.negotiate-auth.trusted-uris/d' /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js > /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.e;
						echo 'user_pref("network.negotiate-auth.trusted-uris", "$domain");' >> /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.e;
						mv /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.e /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js;
						echo "USER $i: network.negotiate-auth.trusted-uris is now set to $domain using SED";
					else
    					echo 'user_pref("network.negotiate-auth.trusted-uris", "$domain");' >> /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.;
    					echo "USER $i: network.negotiate-auth.trusted-uris is now set to $domain";
    				fi	
    			done
	fi
done

}

killFirefox(){

#LoginWindowPID=`pgrep firefox`; This command only works with 10.8 machines
ps -ax | grep -i "Firefox.app" | grep -v grep
if [ $? == 0 ];
	then
		firefoxPID=`ps -ax | grep -i firefox | head -1 | cut -d "?" -f1 | sed 's/^[ \t]*//;s/[ \t]*$//'`;
		kill -9 $firefoxPID
		echo "Killing Firefox"
fi

}

killFirefox;
globalSettings;
userSettings;

exit 0;