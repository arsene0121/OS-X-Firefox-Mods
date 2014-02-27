#!/bin/bash
#Written by Tom Burgin | NIMH | burgintj@nimh.nih.gov
#run with sudo
#This script will enable kerberos pass through to all domain.gov websites in firefox.

globalSettings(){


if grep 'network.negotiate-auth.trusted-uris' /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js;
then
	sudo sed '/network.negotiate-auth.trusted-uris/d' /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js > /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js.e;
	echo 'pref("network.negotiate-auth.trusted-uris", "domain.gov");' >> /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js.e;
	mv /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js.e /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js
	echo "GLOBAL: network.negotiate-auth.trusted-uris is now set to domain.gov using SED"
else
    echo 'pref("network.negotiate-auth.trusted-uris", "domain.gov");' >> /Applications/Firefox.app/Contents/MacOS/defaults/pref/channel-prefs.js;
    	echo "GLOBAL: network.negotiate-auth.trusted-uris is now set to domain.gov"

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
			profileArray=( `ls /Users/$i/Library/Application\ Support/Firefox/Profiles | grep -v DS_Store` )
			for p in ${profileArray[@]};
				do
					if grep 'network.negotiate-auth.trusted-uris' /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js;
					then
						sudo sed '/network.negotiate-auth.trusted-uris/d' /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js > /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.e;
						echo 'user_pref("network.negotiate-auth.trusted-uris", "domain.gov");' >> /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.e;
						mv /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.e /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js;
						echo "USER $i: network.negotiate-auth.trusted-uris is now set to domain.gov using SED";
					else
    					echo 'user_pref("network.negotiate-auth.trusted-uris", "domain.gov");' >> /Users/$i/Library/Application\ Support/Firefox/Profiles/$p/prefs.js.;
    					echo "USER $i: network.negotiate-auth.trusted-uris is now set to domain.gov";
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
