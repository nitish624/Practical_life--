#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
arch=$(uname -m)
# username=$(getent group sudo | awk -F ':' '{print $4}' | cut -d ',' -f1) # Termux पर 'sudo' समूह का उपयोग करने से बचें

# Termux environment में, उपयोगकर्ता नाम 'root' हो सकता है यदि स्क्रिप्ट sudo के साथ चल रही है,
# लेकिन अगर 'proot' के अंदर चल रही है, तो यह 'android' या कोई अन्य उपयोगकर्ता हो सकता है।
# GNOME config के लिए, हम /root या /home/$username का उपयोग कर सकते हैं।
# चूंकि यह Ubuntu rootfs के अंदर चलने के लिए है, हम rootfs के उपयोगकर्ता नाम का उपयोग करेंगे।
# यहाँ, मैंने username को $SUDO_USER या root पर सेट किया है।
if [ -z "$SUDO_USER" ]; then
    username="root"
else
    username="$SUDO_USER"
fi


check_root(){
	if [ "$(id -u)" -ne 0 ]; then
		echo -ne " ${R}Run this program as root!\n\n"${W}
		exit 1
	fi
}

banner() {
	clear
	cat <<- EOF
		${Y}    _  _ ___ ___ ___  ___ _  _
		${C}    |\ |  |   |   |  |__  |__|
		${G}    | \| _|_  |  _|_  __| |  |

	EOF
	echo -e "${G}     A modded gui version of ubuntu (GNOME) for Termux\n"
}

note() {
	banner
	echo -e " ${G} [-] Successfully Installed !\n"${W}
	sleep 1
	cat <<- EOF
		 ${G}[-] Type ${C}vncstart${G} to run Vncserver.
		 ${G}[-] Type ${C}vncstop${G} to stop Vncserver.

		 ${C}Install VNC VIEWER Apk on your Device.

		 ${C}Open VNC VIEWER & Click on + Button.

		 ${C}Enter the Address localhost:1 & Name anything you like.
	
		 ${C}Set the Picture Quality to High for better Quality.

		 ${C}Click on Connect & Input the Password.
		 
		 ${R}NOTE: First run of GNOME may take time to load, please be patient!
		 ${C}Enjoy :D${W}
	EOF
}

package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages for GNOME..."${W}
	apt-get update -y
	# Udisks2 fix - Termux/proot environments के लिए
	apt install udisks2 -y
	rm -f /var/lib/dpkg/info/udisks2.postinst
	echo "" > /var/lib/dpkg/info/udisks2.postinst
	dpkg --configure -a
	apt-mark hold udisks2
	
	# GNOME के लिए मुख्य पैकेज
	# 'ubuntu-desktop' बहुत बड़ा है, इसलिए हम 'gnome-core' का उपयोग करेंगे
	# और VNC सर्वर को 'tigervnc' ही रखेंगे
	packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core gnome-core gnome-terminal gnome-session gdm3 tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 apt-transport-https)
	
	for hulu in "${packs[@]}"; do
		type -p "$hulu" &>/dev/null || {
			echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$hulu${W}"
			# 'gnome-core' एक बहुत बड़ा metapackage है, इसमें समय लगेगा
			apt-get install "$hulu" -y 
		}
	done
	
	apt-get update -y
	apt-get upgrade -y
}
# ---
# install_apt, install_vscode, install_sublime, install_firefox, install_softwares, downloader फ़ंक्शन समान रहेंगे।
# ---

install_apt() {
	for apt in "$@"; do
		[[ `command -v $apt` ]] && echo "${Y}${apt} is already Installed!${W}" || {
			echo -e "${G}Installing ${Y}${apt}${W}"
			apt install -y ${apt}
		}
	done
}

install_vscode() {
	[[ $(command -v code) ]] && echo "${Y}VSCode is already Installed!${W}" || {
		echo -e "${G}Installing ${Y}VSCode${W}"
		curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
		install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
		echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
		apt update -y
		apt install code -y
		echo "Patching.."
		# GNOME के लिए यह पैच आवश्यक नहीं हो सकता है, लेकिन हम इसे सुरक्षित रखने के लिए रखते हैं
		# लेकिन यह पैच xfce4 के लिए था, इसलिए इसे हटा देते हैं या GNOME के लिए संशोधित करते हैं।
		# Termux VNC सेटअप में, .desktop फ़ाइलें अक्सर काम नहीं करतीं।
		# curl -fsSL https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/patches/code.desktop > /usr/share/applications/code.desktop
		echo -e "${C} Visual Studio Code Installed Successfully\n${W}"
	}
}

install_sublime() {
	[[ $(command -v subl) ]] && echo "${Y}Sublime is already Installed!${W}" || {
		apt install gnupg2 software-properties-common --no-install-recommends -y
		echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
		curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/sublime.gpg 2> /dev/null
		apt update -y
		apt install sublime-text -y 
		echo -e "${C} Sublime Text Editor Installed Successfully\n${W}"
	}
}

install_firefox() {
	[[ $(command -v firefox) ]] && echo "${Y}Firefox is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Firefox${W}"
		# यह स्क्रिप्ट Xfce4-आधारित थी। हम इसे डिफ़ॉल्ट apt install से बदल सकते हैं।
		# bash <(curl -fsSL "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/firefox.sh")
		apt install firefox -y
		echo -e "${G} Firefox Installed Successfully\n${W}"
	}
}

install_chromium() {
	[[ $(command -v chromium-browser) ]] && echo "${Y}Chromium is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Chromium${W}"
		apt install chromium-browser -y
		echo -e "${G} Chromium Installed Successfully\n${W}"
	}
}

install_softwares() {
	banner
	cat <<- EOF
		${Y} ---${G} Select Browser ${Y}---

		${C} [${W}1${C}] Firefox (Default)
		${C} [${W}2${C}] Chromium
		${C} [${W}3${C}] Both (Firefox + Chromium)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" BROWSER_OPTION
	banner

	# 'armhf' (जैसे Raspberry Pi 1) के अलावा अन्य आर्किटेक्चर पर IDE विकल्प दिखाना
	if [[ ! ("$arch" == 'armhf' || "$arch" == *'armv7'*) ]]; then
		cat <<- EOF
			${Y} ---${G} Select IDE ${Y}---

			${C} [${W}1${C}] Sublime Text Editor (Recommended)
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] Both (Sublime + VSCode)
			${C} [${W}4${C}] Skip! (Default)

		EOF
		read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
		banner
	fi
	
	cat <<- EOF
		${Y} ---${G} Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] Both (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
	{ banner; sleep 1; }

	if [[ ${BROWSER_OPTION} == 2 ]]; then
		install_chromium
	elif [[ ${BROWSER_OPTION} == 3 ]]; then
		install_firefox
		install_chromium
	else
		install_firefox
	fi

	if [[ ! ("$arch" == 'armhf' || "$arch" == *'armv7'*) ]]; then
		if [[ ${IDE_OPTION} == 1 ]]; then
			install_sublime
		elif [[ ${IDE_OPTION} == 2 ]]; then
			install_vscode
		elif [[ ${IDE_OPTION} == 3 ]]; then
			install_sublime
			install_vscode
		else
			echo -e "${Y} [!] Skipping IDE Installation\n"
			sleep 1
		fi
	fi

	if [[ ${PLAYER_OPTION} == 1 ]]; then
		install_apt "mpv"
	elif [[ ${PLAYER_OPTION} == 2 ]]; then
		install_apt "vlc"
	elif [[ ${PLAYER_OPTION} == 3 ]]; then
		install_apt "mpv" "vlc"
	else
		echo -e "${Y} [!] Skipping Media Player Installation\n"
		sleep 1
	fi

}

downloader(){
	path="$1"
	[[ -e "$path" ]] && rm -rf "$path"
	echo "Downloading $(basename $1)..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		  --location --output ${path} "$2"
}

sound_fix() {
	# यह line VNC start script (ubuntu) में sound fix के लिए एक command insert करती है
	# VNC start script का पता बदल सकता है, लेकिन हम मान रहे हैं कि यह /data/data/com.termux/files/usr/bin/ubuntu है
	# और इसे पहले से ही Termux के द्वारा बनाया गया है।
	# Termux user sound fix के लिए:
	echo "$(echo "bash ~/.sound" | cat - /data/data/com.termux/files/usr/bin/ubuntu)" > /data/data/com.termux/files/usr/bin/ubuntu
	# Rootfs environment variables
	echo "export DISPLAY=":1"" >> /etc/profile
	echo "export PULSE_SERVER=127.0.0.1" >> /etc/profile 
	source /etc/profile
}

# Xfce4 theme/icon removal functions को GNOME के लिए हटा दिया गया है
# क्योंकि GNOME के साथ अलग themes/icons आते हैं।

config() {
	banner
	sound_fix

	# GNOME VNC/dbus setup
	# VNC Server को GNOME सेशन शुरू करने के लिए कॉन्फ़िगर करें
	# VNC server start script (~/.vnc/xstartup) को GNOME के लिए संशोधित करें
	
	VNC_STARTUP_FILE="/home/$username/.vnc/xstartup"
	
	# यदि उपयोगकर्ता 'root' नहीं है, तो सुनिश्चित करें कि home directory मौजूद है
	if [ "$username" != "root" ]; then
		mkdir -p /home/$username
		chown -R $username:$username /home/$username
	fi

	# .vnc directory बनाएं
	mkdir -p /home/$username/.vnc
	
	cat <<- EOF > $VNC_STARTUP_FILE
		#!/bin/bash
		xrdb $HOME/.Xresources
		export XDG_CURRENT_DESKTOP="GNOME"
		export XDG_SESSION_TYPE="vnc"
		export XDG_SESSION_DESKTOP="gnome"
		export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"

		# GNOME environment को dbus के साथ शुरू करने के लिए आवश्यक
		if [ -e /etc/dbus-1/system.conf ] ; then
			dbus-daemon --config-file=/etc/dbus-1/system.conf --fork
		else
			dbus-daemon --session --fork
		fi
		
		# GDM3 VNC start fix
		# GNOME 3 VNC के माध्यम से शुरू करने का तरीका
		/usr/lib/gnome-session/gnome-session-start &
		
		# GNOME 40+ के लिए: 
		# gnome-session &
		
		# Fallback in case gnome-session fails (पुराने GNOME के लिए)
		# gnome-shell & 

	EOF
	
	# सुनिश्चित करें कि xstartup executable है
	chmod +x $VNC_STARTUP_FILE
	chown -R $username:$username /home/$username/.vnc

	# Xfce4-आधारित customizations को हटा दिया गया है, क्योंकि GNOME का अपना configuration होता है
	# और Xfce4 themes/settings GNOME के साथ असंगत हो सकते हैं।
	
	echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n"${W}
	fc-cache -fv

	echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n"${W}
	apt update
	yes | apt upgrade
	apt clean
	yes | apt autoremove

}

# ----------------------------

check_root
package
install_softwares
config
note
