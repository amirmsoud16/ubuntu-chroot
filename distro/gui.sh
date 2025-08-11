https://github.com/amirmsoud16/ubuntu-chroot.git#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
arch=$(uname -m)
# Prefer an existing normal user (uid >= 1000), fallback to SUDO_USER/USER
username=$(getent passwd | awk -F: '$3>=1000 && $1!="nobody" {print $1; exit}')
username=${username:-${SUDO_USER:-${USER:-}}}

check_root(){
	if [ "$(id -u)" -ne 0 ]; then
		echo -ne " ${R}Run this program as root!\n\n"${W}
		exit 1
	fi
}

banner() {
	clear
	cat <<- EOF
		${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  
		${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ 
		${G}    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ 

	EOF
	echo -e "${G}     A modded gui version of ubuntu for Termux\n"
}

note() {
	banner
	echo -e " ${G} [-] Successfully Installed !\n"${W}
	sleep 1
	cat <<- EOF
		 ${G}[-] Type ${C}./vncstart${G} to run Vncserver.
		 ${G}[-] Type ${C}./vncstop${G} to stop Vncserver.

		 ${C}Install VNC VIEWER Apk on your Device.

		 ${C}Open VNC VIEWER & Click on + Button.

		 ${C}Enter the Address localhost:1 & Name anything you like.

		 ${C}Set the Picture Quality to High for better Quality.

		 ${C}Click on Connect & Input the Password.

		 ${C}Enjoy :D${W}
	EOF
}

package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages..."${W}
	apt-get update -y
	# Avoid udisks2 in chroot; it is unnecessary and problematic
	# Ensure dpkg is configured
	dpkg --configure -a || true
	
	packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https)
	for hulu in "${packs[@]}"; do
		type -p "$hulu" &>/dev/null || {
			echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$hulu${W}"
			apt-get install -y --no-install-recommends "$hulu"
		}
	done
	
	apt-get update -y
	apt-get upgrade -y
}

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
		# Avoid overwriting system desktop files blindly; only add --no-sandbox if needed
		if grep -q "Exec=code %U" /usr/share/applications/code.desktop 2>/dev/null; then
			sed -i 's|Exec=code %U|Exec=code --no-sandbox %U|' /usr/share/applications/code.desktop || true
		fi
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

install_chromium() {
	[[ $(command -v chromium) ]] && echo "${Y}Chromium is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Chromium${W}"
		apt-get purge -y chromium* chromium-browser* snapd || true
		apt-get install -y --no-install-recommends gnupg2 software-properties-common
		# Prefer Ubuntu repositories for Chromium when available
		apt-get update -y
		apt-get install -y chromium || apt-get install -y chromium-browser || true
		sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop 2>/dev/null || true
		echo -e "${G} Chromium Installed Successfully\n${W}"
	}
}

install_firefox() {
	[[ $(command -v firefox) ]] && echo "${Y}Firefox is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Firefox${W}"
		bash <(curl -fsSL "https://raw.githubusercontent.com/modded-ubuntu/modded-ubuntu/master/distro/firefox.sh")
		echo -e "${G} Firefox Installed Successfully\n${W}"
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

	[[ "$arch" != 'armhf' && "$arch" != armv7* ]] && {
		cat <<- EOF
			${Y} ---${G} Select IDE ${Y}---

			${C} [${W}1${C}] Sublime Text Editor (Recommended)
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] Both (Sublime + VSCode)
			${C} [${W}4${C}] Skip! (Default)

		EOF
		read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
		banner
	}
	
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

	[[ ("$arch" != 'armhf') || ("$arch" != *'armv7'*) ]] && {
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
	}

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
	curl --progress-bar --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		  --location --output ${path} "$2"
}

sound_fix() {
	# Configure desktop environment variables for chroot
	install -d /etc/profile.d
	cat > /etc/profile.d/desktop.sh <<'EOF'
export DISPLAY=${DISPLAY-:1}
export PULSE_SERVER=${PULSE_SERVER-127.0.0.1}
EOF
	chmod 0644 /etc/profile.d/desktop.sh

	# Optionally ensure the target user's shell profile has these as well
	if [ -n "${username:-}" ] && [ -d "/home/$username" ]; then
		user_profile="/home/$username/.profile"
		touch "$user_profile"
		grep -q '^export DISPLAY=' "$user_profile" || printf '\nexport DISPLAY=:1\n' >> "$user_profile"
		grep -q '^export PULSE_SERVER=' "$user_profile" || printf 'export PULSE_SERVER=127.0.0.1\n' >> "$user_profile"
		chown "$username:$username" "$user_profile"
	fi

	# Load into current shell session if possible
	. /etc/profile.d/desktop.sh || true
}

rem_theme() {
	theme=(Bright Daloa Emacs Moheli Retro Smoke)
	for rmi in "${theme[@]}"; do
		if [ -d "/usr/share/themes/$rmi" ]; then
			rm -rf "/usr/share/themes/$rmi"
		fi
	done
}

rem_icon() {
	fonts=(hicolor LoginIcons ubuntu-mono-light)
	for rmf in "${fonts[@]}"; do
		if [ -d "/usr/share/icons/$rmf" ]; then
			rm -rf "/usr/share/icons/$rmf"
		fi
	done
}

config() {
	banner
	sound_fix

	# Avoid deprecated apt-key; rely on existing distro keys
	apt-get update -y
	apt-get upgrade -y
	apt-get install -y --no-install-recommends gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin
	mv -vf /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfceverticals-old.png || true
	temp_folder=$(mktemp -d -p "$HOME")
	{ banner; sleep 1; cd $temp_folder; }

	echo -e "${R} [${W}-${R}]${C} Downloading Required Files..\n"${W}
	downloader "fonts.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/fonts.tar.gz"
	downloader "icons.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/icons.tar.gz"
	downloader "wallpaper.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/wallpaper.tar.gz"
	downloader "gtk-themes.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/gtk-themes.tar.gz"
	downloader "ubuntu-settings.tar.gz" "https://github.com/modded-ubuntu/modded-ubuntu/releases/download/config/ubuntu-settings.tar.gz"

	echo -e "${R} [${W}-${R}]${C} Unpacking Files..\n"${W}
	tar -xvzf fonts.tar.gz -C "/usr/local/share/fonts/"
	tar -xvzf icons.tar.gz -C "/usr/share/icons/"
	tar -xvzf wallpaper.tar.gz -C "/usr/share/backgrounds/xfce/"
	tar -xvzf gtk-themes.tar.gz -C "/usr/share/themes/"
	# Ensure home exists and has proper ownership
	install -d -m 0755 "/home/$username" || true
	tar -xvzf ubuntu-settings.tar.gz -C "/home/$username/"
	chown -R "$username:$username" "/home/$username" || true
	rm -fr $temp_folder

	echo -e "${R} [${W}-${R}]${C} Purging Unnecessary Files.."${W}
	rem_theme
	rem_icon

	echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n"${W}
	fc-cache -fv

	echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n"${W}
	apt-get update -y
	apt-get upgrade -y
	apt-get clean
	apt-get -y autoremove

}

# ----------------------------

check_root
package
install_softwares
config
note

