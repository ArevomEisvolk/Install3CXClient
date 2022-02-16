#!/bin/bash
# "$HOME/.gateos/wineprefix/3CXLinux" win64 $HOME/.gateos/wine/lutris-fshack-7.1-x86_64/bin/wine $HOME/.gateos/wineprefix/3CXLinux/dosdevices/c\:/ProgramData/3CXPhone\ for\ Windows/PhoneApp/3CXWin8Phone.exe"
export PROGRAM_NAME="3CXClient"
export INSTALLER_TITLE="3CX Linux Installer"
export LOCALBIN="$HOME/bin"
export DESKTOPDIR=$(xdg-user-dir DESKTOP)
export WINEDESKTOPFILE="$DESKTOPDIR/3CXPhone for Windows.desktop"
export WINELNKFILE="$DESKTOPDIR/3CXPhone for Windows.lnk"
export WINEDOWNLOADLINK="https://github.com/lutris/wine/releases/download/lutris-7.1/wine-lutris-7.1-x86_64.tar.xz"
export WINEDOWNLOADFILE="wine-lutris-7.1-x86_64.tar.xz"
export PROGRAMDOWNLOADLINK="http://downloads.3cx.com/downloads/3CXPhoneforWindows16.msi"
export PROGRAMDOWNLOADFILE="3CXPhoneforWindows16.msi"
export WINEPREFIX="$HOME/.gateos/wineprefix/3CXLinux"
export WINETRICKSEXEC="$LOCALBIN/winetricks"
export PROGRAMPATH="$WINEPREFIX/dosdevices/c\:/ProgramData/3CXPhone\ for\ Windows/PhoneApp"
export PROGRAMEXEC="$PROGRAMPATH/3CXWin8Phone.exe"
export APPLICATIONEXEC="$LOCALBIN/3CXClient"
export WINEBINS="$HOME/.gateos/wine"
export WINEFOLDER="$WINEBINS/lutris-7.1-x86_64"
export WINEEXEC="$WINEFOLDER/bin/wine"
export WINEARCH="win64"
export WINVERSION=""
export APPLICATIONFOLDER="$HOME/.local/share/applications"
export APPLICATIONPATH="$APPLICATIONFOLDER/3CXClient.desktop"
export ICONPATH="$HOME/.local/share/icons/3CXClient.png"

create_fresh_install_environment() {
    rm -rf $WINEPREFIX
    rm -rf $WINEFOLDER
    rm $APPLICATIONEXEC
    mkdir -p $WINEPREFIX
    mkdir -p $WINEBINS
    mkdir -p $LOCALBIN
}

remove_prefix() {
    rm -rf $WINEPREFIX
}

download_progress() {
    rand="$random `date`"
    pipe="/tmp/pipe.`echo '$rand' | md5sum | tr -d ' -'`"
    mkfifo $pipe
    wget -c $1 2>&1 | while read data;do
    if [ "`echo $data | grep '^length:'`" ]; then
        total_size=`echo $data | grep "^length:" | sed 's/.*\((.*)\).*/\1/' | tr -d '()'`
    fi
    if [ "`echo $data | grep '[0-9]*%' `" ];then
        percent=`echo $data | grep -o "[0-9]*%" | tr -d '%'`
        current=`echo $data | grep "[0-9]*%" | sed 's/\([0-9bkmg.]\+\).*/\1/' `
        speed=`echo $data | grep "[0-9]*%" | sed 's/.*\(% [0-9bkmg.]\+\).*/\1/' | tr -d ' %'`
        remain=`echo $data | grep -o "[0-9a-za-z]*$" `
        echo $percent
        echo "#downloading $1\n$current of $total_size ($percent%)\nspeed : $speed/sec\nestimated time : $remain"
    fi
    done > $pipe &

    wget_info=`ps ax |grep "wget.*$1" |awk '{print $1"|"$2}'`
    wget_pid=`echo $wget_info|cut -d'|' -f1 `

    zenity --progress --auto-close --text="connecting to $1\n\n\n" --width="350" --title="$INSTALLER_TITLE"< $pipe
    if [ "`ps -a |grep "$wget_pid"`" ];then
        kill $wget_pid
    fi
    rm -f $pipe
}

create_prefix() {
    zenity --info --text "Wineprefix will be created now." --title "$INSTALLER_TITLE"
    WINEPREFIX=$WINEPREFIX winecfg WINEARCH=win64 $WINEEXEC wineboot 
    # make sure instance will be ready for next launch
    killall wineserver
    killall wine
}

install_procedure_vcrun() {
    zenity --info --text="Installing Vcrun2019"
    (
        WINEPREFIX=$WINEPREFIX WINEARCH=win64 $WINETRICKSEXEC vcrun2019 vcrun2015
    ) | zenity --progress --text="Vcrun2019 installations in progress" title="$INSTALLER_TITLE" --pulsate
}

install_procedure_devenum() {
    zenity --info --text="Installing devenum"
    (
        WINEPREFIX=$WINEPREFIX WINEARCH=win64 $WINETRICKSEXEC devenum
    ) | zenity --progress --text="devenum installations in progress" title="$INSTALLER_TITLE" --pulsate
}

install_procedure_dotnet() {
    zenity --info --text="Now there will be a cascade of 3 installs of .NET Versions.\nPlease ignore all possibly seen warnings and proceed all install steps with default values.\nIf you'll be asked for restarting, it doesn't matter which option to select due to it has no impact on the installation."
    (
        WINEPREFIX=$WINEPREFIX WINEARCH=win64 $WINETRICKSEXEC dotnet461
    ) | zenity --progress --text="Dotnet installations in progress" title="$INSTALLER_TITLE" --pulsate
    zenity --info --text "$PROGRAM_NAME will be installed next. Please leave everything default and just proceed through installation." --title "$INSTALLER_TITLE"
    WINEPREFIX=$WINEPREFIX WINEARCH=win64 $WINE msiexec /i /tmp/$PROGRAMDOWNLOADFILE
    rm /tmp/$PROGRAMDOWNLOADFILE
}

provide_wine_version() {
    zenity --notification --text="Downloading wine version 7.1 64bit from lutris"
    download_progress "$WINEDOWNLOADLINK"
    wget "$WINEDOWNLOADLINK"
    tar -xf ./$WINEDOWNLOADFILE -C $WINEBINS
    rm ./$WINEDOWNLOADFILE
}

download_program() {
    zenity --notification --text="Downloading 3CX Windows Client"
    download_progress "$PROGRAMDOWNLOADLINK"
    mv ./$PROGRAMDOWNLOADFILE /tmp/
}

install_winetricks() {
    if [ ! -d "$LOCALBIN" ]; then
        mkdir $LOCALBIN
    fi
    (
        wget http://winetricks.org/winetricks -O $WINETRICKSEXEC
        chmod a+x $WINETRICKSEXEC
    ) | zenity --progress --no-cancel --pulsate --auto-close --text="Download and locally install latest winetricks" --title="$INSTALLER_TITLE"
}

create_application_entry() {
wget https://cdn6.aptoide.com/imgs/c/0/e/c0e8f423f28399b816cda37f8facb566_icon.png?w=256 -O $ICONPATH
cat << EOF > $APPLICATIONEXEC
#/bin/sh
WINEPREFIX=$WINEPREFIX WINEARCH=win64 $WINEEXEC $PROGRAMEXEC
EOF
chmod a+x $APPLICATIONEXEC
cat << EOF > $APPLICATIONPATH
[Desktop Entry]
Name=3CXClient
GenericName=3CXClient for Linux
GenericName[de]=3CXClient für Linux
Comment=Telefon for 3CX PBX
Comment[de]=Telefon für 3CX Telefonanlage
Exec=sh $APPLICATIONEXEC
Icon=$ICONPATH
Terminal=false
Type=Application
StartupNotify=true
Categories=Network;Utility
EOF
}

remove_application_entry() {
    rm $APPLICATIONPATH
    rm $APPLICATIONEXEC
    rm $ICONPATH
}

ask_for_action() {
    SCRIPTACTION=$(zenity  --list  --text "Choose Action?" --title="$INSTALLER_TITLE" --column "Action" "Install" "Uninstall" "Leave")
    export $SCRIPTACTION
}

remove_wine_desktop_files() {
    rm "$WINEDESKTOPFILE"
    rm "$WINELNKFILE"
    rm -rf "$APPLICATIONFOLDER/wine/Programs/3CXPhone for Windows/"
}

#main

ask_for_action

if [ "$SCRIPTACTION" = "Install" ]; then
    create_fresh_install_environment
    provide_wine_version
    download_program
    install_winetricks
    create_prefix
    install_procedure_devenum
    install_procedure_vcrun
    install_procedure_dotnet
    create_application_entry
    remove_wine_desktop_files
    zenity --notification --text="Completely installed $PROGRAM_NAME"
fi

if [ "$SCRIPTACTION" = "Uninstall" ]; then
    remove_prefix
    remove_application_entry
    remove_wine_desktop_files
    zenity --notification --text="Removed $PROGRAM_NAME"
fi

exit 0
