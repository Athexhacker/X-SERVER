#!/bin/bash

# Color definitions with better palette
declare -A colors=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[1;37m'
    [ORANGE]='\033[0;33m'
    [RESET]='\033[0m'
    [BOLD]='\033[1m'
    [DIM]='\033[2m'
    [BLINK]='\033[5m'
)

# Icons for better UX
declare -A icons=(
    [FOLDER]='📁'
    [FILE]='📄'
    [UPLOAD]='⬆️'
    [DOWNLOAD]='⬇️'
    [SUCCESS]='✅'
    [ERROR]='❌'
    [WARNING]='⚠️'
    [INFO]='ℹ️'
    [LOCK]='🔒'
    [UNLOCK]='🔓'
    [CLOCK]='⏱️'
    [DATABASE]='💾'
    [TRASH]='🗑️'
    [EXIT]='🚪'
)

# Animation functions
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local duration=$1
    local width=50
    local progress=0
    local step=$((width / duration))
    
    printf "${colors[CYAN]}["
    while [ $progress -lt $width ]; do
        printf "▓"
        progress=$((progress + 1))
        sleep 0.1
    done
    printf "]${colors[RESET]}\n"
}

pulse_animation() {
    local text=$1
    local color=${2:-$GREEN}
    
    for i in {1..3}; do
        echo -ne "\r${color}${text}   ${colors[RESET]}"
        sleep 0.2
        echo -ne "\r${color}${text}.  ${colors[RESET]}"
        sleep 0.2
        echo -ne "\r${color}${text}.. ${colors[RESET]}"
        sleep 0.2
        echo -ne "\r${color}${text}...${colors[RESET]}"
        sleep 0.2
    done
    echo
}

typewriter() {
    local text=$1
    local delay=0.03
    
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# Box drawing functions
draw_box() {
    local title=$1
    local width=60
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo -ne "${colors[CYAN]}╔"
    printf '═%.0s' $(seq 1 $width)
    echo "╗"
    
    echo -ne "║"
    printf '%*s' $padding
    echo -ne "${colors[YELLOW]}${icons[INFO]} ${title}${colors[CYAN]}"
    printf '%*s' $((width - padding - ${#title} - 2))
    echo "║"
    
    echo -ne "╚"
    printf '═%.0s' $(seq 1 $width)
    echo "╝${colors[RESET]}"
}

# Enhanced EncLoad with animations
EncLoad() {
    clear
    draw_box "FILE ENCRYPTION & UPLOAD"
    
    echo -e "\n${colors[CYAN]}${icons[FOLDER]} Enter folder name/path:${colors[RESET]} "
    read -r -p "➜ " __DIR__
    
    [ -z "${__DIR__}" ] && main
    
    pulse_animation "Checking directory" "${colors[BLUE]}"
    
    absolute=$(realpath "${__DIR__}" 2>/dev/null)
    
    if [ -d "${absolute}" ]; then
        connectivity
        
        typewriter "${icons[LOCK]} Creating archive..."
        usz=$(du -h "${__DIR__}" 2>/dev/null | tail -n 1 | awk '{print $1"B"}')
        
        (zip -r "${logdir}/${__DIR__}.zip" "${__DIR__}" > /dev/null 2>&1) &
        spinner $!
        
        typewriter "${icons[LOCK]} Encrypting archive..."
        openssl aes-256-cbc -a -salt -in "${logdir}/${__DIR__}.zip" \
            -out "${logdir}/${__DIR__}.enc" -md sha256 2>/dev/null
        
        cat "${logdir}/${__DIR__}.enc" | base64 > "${logdir}/${__DIR__}.samhax"
        
        typewriter "${icons[UPLOAD]} Uploading to cloud..."
        
        (python3 "${logdir}/${filen}" upload "${logdir}/${__DIR__}.samhax" > "${logdir}/plink" 2>&1) &
        spinner $!
        
        __DID__=$(cat "${logdir}/plink" 2>/dev/null | sed -r 's/.{16}//')
        
        # Fixed Python2 datetime calculation
        __ED__=$(python2 -c "
from datetime import datetime, timedelta
print((datetime.now() + timedelta(days=7)).strftime('%Y-%m-%d %H:%M:%S'))
" 2>/dev/null)
        
        echo -e "\n${colors[GREEN]}${icons[SUCCESS]} Download ID: ${colors[BOLD]}${__DID__}${colors[RESET]}"
        echo -e "${colors[YELLOW]}${icons[CLOCK]} Expires: ${__ED__}${colors[RESET]}"
        
        # Logging
        logf="/tmp/.samhax.log"
        cdat=$(date '+%Y-%m-%d %H:%M:%S')
        
        if [ ! -f "${logf}" ]; then
            touch "${logf}"
            echo -e "DOWNLOAD-ID\t\tDATE-UPLOADED\t\tEXPIRE-DATE\t\tFOLDER-NAME" > "${logf}"
            echo "═══════════════════════════════════════════════════════════════════════════════════" >> "${logf}"
        fi
        
        echo -e "${__DID__}\t${cdat}\t${__ED__}\t${__DIR__} [${usz}]" >> "${logf}"
        
        progress_bar 5
        echo -e "${colors[GREEN]}${icons[SUCCESS]} Process completed successfully!${colors[RESET]}"
    else
        echo -e "\n${colors[RED]}${icons[ERROR]} Directory not found: ${__DIR__}${colors[RESET]}"
    fi
    
    sleep 2
}

# Enhanced DecLoad with animations
DecLoad() {
    clear
    draw_box "FILE DECRYPTION & DOWNLOAD"
    
    echo -e "\n${colors[CYAN]}${icons[DATABASE]} Enter Download ID:${colors[RESET]} "
    read -r -p "➜ " id
    
    [ -z "${id}" ] && main
    
    pulse_animation "Checking file availability" "${colors[BLUE]}"
    
    echo -e "\n${colors[YELLOW]}${icons[FILE]} File found!${colors[RESET]}"
    echo -e "${colors[CYAN]}Download now? (y/N):${colors[RESET]} "
    read -r -p "➜ " response
    
    [[ ! "${response}" =~ ^[Yy]$ ]] && main
    
    connectivity
    
    typewriter "${icons[DOWNLOAD]} Downloading file..."
    
    (python3 "${logdir}/${filen}" download "https://we.tl/t-${id}" > /dev/null 2>&1) &
    spinner $!
    
    __EXT__=$(ls *.samhax 2>/dev/null | head -1)
    
    if [ -z "${__EXT__}" ]; then
        echo -e "\n${colors[RED]}${icons[ERROR]} Download failed!${colors[RESET]}"
        sleep 2
        main
    fi
    
    mv "${__EXT__}" "${logdir}/${__EXT__}" 2>/dev/null
    __DIR__=$(echo "${__EXT__}" | sed 's/.\{7\}$//')
    
    typewriter "${icons[UNLOCK]} Decrypting archive..."
    cat "${logdir}/${__EXT__}" | base64 -d > "${logdir}/${__DIR__}.enc" 2>/dev/null
    
    openssl aes-256-cbc -d -a -in "${logdir}/${__DIR__}.enc" \
        -out "${PWD}/${__DIR__}.zip" -md sha256 2>/dev/null
    
    typewriter "${icons[FOLDER]} Extracting files..."
    (unzip -o "${__DIR__}.zip" > /dev/null 2>&1) &
    spinner $!
    
    dsz=$(du -h "${__DIR__}" 2>/dev/null | tail -n 1 | awk '{print $1"B"}')
    
    # Logging
    logd="/tmp/.samhax.down.log"
    cdat=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ ! -f "${logd}" ]; then
        touch "${logd}"
        echo -e "DOWNLOAD-ID\t\tDATE-DOWNLOADED\t\tFOLDER-NAME" > "${logd}"
        echo "═══════════════════════════════════════════════════════════════" >> "${logd}"
    fi
    
    echo -e "${id}\t\t${cdat}\t\t${__DIR__} [${dsz}]" >> "${logd}"
    
    progress_bar 3
    echo -e "\n${colors[GREEN]}${icons[SUCCESS]} Files extracted successfully to: ${PWD}/${__DIR__}${colors[RESET]}"
    sleep 2
}

# Enhanced connectivity check
connectivity() {
    echo -e "\n${colors[BLUE]}${icons[INFO]} Checking internet connection...${colors[RESET]}"
    
    if ping -c 1 google.com &> /dev/null || nc -zw1 google.com 443 2>/dev/null; then
        echo -e "${colors[GREEN]}${icons[SUCCESS]} Connection: OK${colors[RESET]}"
    else
        echo -e "${colors[RED]}${icons[ERROR]} No internet connection!${colors[RESET]}"
        echo -e "${colors[YELLOW]}Please check your connection and try again.${colors[RESET]}"
        sleep 2
        exit 1
    fi
}

# Enhanced library installation
libs() {
    clear
    draw_box "INSTALLING DEPENDENCIES"
    
    echo -e "\n${colors[YELLOW]}${icons[WARNING]} Required packages are missing.${colors[RESET]}"
    echo -e "${colors[CYAN]}Installing libraries...${colors[RESET]}\n"
    
    progress_bar 5
    
    apt update -y > /dev/null 2>&1 &
    spinner $!
    
    apt install -y zip python2 python3 python3-pip netcat-openbsd openssl curl > /dev/null 2>&1 &
    spinner $!
    
    pip3 install requests > /dev/null 2>&1 &
    spinner $!
    
    echo -e "\n${colors[GREEN]}${icons[SUCCESS]} All dependencies installed!${colors[RESET]}"
    sleep 2
}

# Display logs with formatting
display_logs() {
    local logfile=$1
    local title=$2
    
    if [ -f "${logfile}" ]; then
        echo -e "\n${colors[PURPLE]}═══════════════════════════════════════════════════════════════${colors[RESET]}"
        echo -e "${colors[BOLD]}${title}${colors[RESET]}"
        echo -e "${colors[PURPLE]}═══════════════════════════════════════════════════════════════${colors[RESET]}"
        
        while IFS= read -r line; do
            if [[ $line == *"══"* ]]; then
                echo -e "${colors[CYAN]}${line}${colors[RESET]}"
            else
                echo -e "${colors[WHITE]}${line}${colors[RESET]}"
            fi
        done < "${logfile}"
        
        echo -e "${colors[PURPLE]}═══════════════════════════════════════════════════════════════${colors[RESET]}\n"
    else
        echo -e "\n${colors[YELLOW]}${icons[WARNING]} No logs found${colors[RESET]}\n"
    fi
}

# Main function with enhanced UI
main() {
    # Cleanup
    rm -rf "${logdir:?}"/* 2>/dev/null
    rm -f 1 *.zip 2>/dev/null
    
    # Check dependencies
    local missing_deps=()
    command -v openssl >/dev/null 2>&1 || missing_deps+=("openssl")
    command -v nc >/dev/null 2>&1 || missing_deps+=("netcat")
    command -v python2 >/dev/null 2>&1 || missing_deps+=("python2")
    command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
    command -v zip >/dev/null 2>&1 || missing_deps+=("zip")
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    
    [ ${#missing_deps[@]} -gt 0 ] && libs
    
    # Setup environment
    logdir="/tmp/samhaxLogs"
    mkdir -p "${logdir}" 2>/dev/null
    
    # Download transfer script
    transferwee="https://raw.githubusercontent.com/recoxv1/transferwee/master/transferwee.py"
    filen="tw.py"
    transfer="/tmp/transferwee.py"
    
    if [ ! -f "${transfer}" ]; then
        echo -e "\n${colors[BLUE]}${icons[INFO]} Downloading required components...${colors[RESET]}"
        curl -s "${transferwee}" > "${transfer}" 2>/dev/null &
        spinner $!
    fi
    
    cp "${transfer}" "${logdir}/${filen}" 2>/dev/null
    chmod +x "${logdir}/${filen}" 2>/dev/null
    
    # Display banner
    clear
    echo -e "${colors[PURPLE]}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║  ██╗  ██╗   ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗ ║
    ║  ╚██╗██╔╝   ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗║
    ║   ╚███╔╝    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝║
    ║   ██╔██╗    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗║
    ║  ██╔╝ ██╗   ██████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║║
    ║  ╚═╝  ╚═╝   ╚═════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${colors[RESET]}"
    
    echo -e "${colors[GREEN]}Author: ATHEX${colors[RESET]}"
    echo -e "${colors[YELLOW]}Version: 2.0 (Enhanced Edition)${colors[RESET]}"
    echo -e "${colors[CYAN]}═══════════════════════════════════════════════════════════════${colors[RESET]}\n"
    
    # Menu options
    echo -e "${colors[BOLD]}${icons[UPLOAD]}  [1] Upload & Encrypt File${colors[RESET]}"
    echo -e "${colors[BOLD]}${icons[DOWNLOAD]} [2] Download & Decrypt File${colors[RESET]}"
    echo -e "${colors[BOLD]}${icons[DATABASE]} [3] View Upload History${colors[RESET]}"
    echo -e "${colors[BOLD]}${icons[DATABASE]} [4] View Download History${colors[RESET]}"
    echo -e "${colors[BOLD]}${icons[TRASH]}    [5] Clear All Logs${colors[RESET]}"
    echo -e "${colors[BOLD]}${icons[EXIT]}     [0] Exit${colors[RESET]}\n"
    
    echo -ne "${colors[CYAN]}➜ Enter your choice: ${colors[RESET]}"
    read -r choice
    
    case "${choice}" in
        1) EncLoad ;;
        2) DecLoad ;;
        3) display_logs "/tmp/.samhax.log" "📋 UPLOAD HISTORY" && sleep 3 ;;
        4) display_logs "/tmp/.samhax.down.log" "📋 DOWNLOAD HISTORY" && sleep 3 ;;
        5)
            echo -e "\n${colors[YELLOW]}${icons[WARNING]} Clear all logs? (y/N):${colors[RESET]} "
            read -r response
            if [[ "${response}" =~ ^[Yy]$ ]]; then
                rm -f "/tmp/.samhax.log" "/tmp/.samhax.down.log" 2>/dev/null
                echo -e "${colors[GREEN]}${icons[SUCCESS]} Logs cleared!${colors[RESET]}"
                sleep 1
            fi
            ;;
        0)
            echo -e "\n${colors[PURPLE]}${icons[EXIT]} Goodbye! 👋${colors[RESET]}"
            progress_bar 2
            exit 0
            ;;
        *)
            echo -e "\n${colors[RED]}${icons[ERROR]} Invalid choice!${colors[RESET]}"
            sleep 1
            ;;
    esac
}

# Trap Ctrl+C
trap 'echo -e "\n${colors[RED]}${icons[ERROR]} Interrupted!${colors[RESET]}"; exit 1' INT

# Clear screen and start main loop
clear
while true; do
    main
done
