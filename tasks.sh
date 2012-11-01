#!/bin/bash

#drupal_deployment verz.
SCRIPTDIR="$(dirname ${BASH_SOURCE[0]})"
STARTSCRIPT=`basename $0`
TASK="$1"
VERBOSE=""

if [ ! -z $TASK ] && [ $TASK = "-v" ];then
  TASK=""
  VERBOSE=-v
fi

source $SCRIPTDIR/functions.sh

_include_common_cfg_file

if [ -z $PROJECT ];then
 incolor_red "In der $STARTSCRIPT Datei fehlt die Angabe des Projectnames PROJECT"
 exit 1
fi

DD_SETTINGS="$HOME/.drupal_deployment/$PROJECT"
if ! [ -d $DD_SETTINGS ];then
 mkdir -vp $DD_SETTINGS
fi

_create_vars
#source $SCRIPTDIR/updates.sh

if [ -z $TASK ];then
  clear
  echo "Was möchtest du tun?"
  echo "[1] Live-Umgebung erstellen"
  echo "[2] Dev-Umgebung erstellen"
  echo "[3] Stage-Umgebung erstellen"
  #echo "[4] Testing-Umgebung erstellen"
  echo "[5] ...weitere Aufgaben"
  incolor_yellow "[x] Beenden"
  read TASK
fi

#wenn $TASK leer startscript erneut aufrufen
if [ -z $TASK ];then
  start_startscript
fi
BUILD_ENV=""

if [[ $TASK = "1" || $TASK = "live" ]];then
  BUILD_ENV="live"
  _build_env
elif [[ $TASK = "2" || $TASK = "dev" ]];then
  BUILD_ENV="dev"
  _build_env
elif [[ $TASK = "3" || $TASK = "stage" ]];then
  BUILD_ENV="stage"
  _build_env
elif [[ $TASK = "4" || $TASK = "testing" ]];then
  BUILD_ENV="testing"
  _build_env
elif [[ $TASK = "5" || $TASK = "tools" ]];then
  clear
  TOOLS_ACTION="$2"
  TOOLS_ENV="$3"
  if [ -z $TOOLS_ACTION ];then
    clear
    echo "[1] Datenbank von Live importieren (SSH-Zugang erforderlich)"
    echo "[2] Lokale Datenbank importieren"
    echo "[3] Lokale Datenbank exportieren"
    echo "[4] Backup wiederherstellen"
    echo "[5] Aktuelles Build packen. (tar-Format und leerem sites/default Ordner)"
    echo "[6] Umgebung bereinigen (Sudoer erforderlich, wenn keine schreibrechte)"
    incolor_yellow "[x] Beenden"
    read TOOLS_ACTION
  fi
  if [ -z $TOOLS_ACTION ];then
    start_startscript
  fi
  if [[ $TOOLS_ACTION = "1" || $TOOLS_ACTION = "sync" ]];then
    TOOLS_ACTION="sync"
    source $SCRIPTDIR/requirements.sh
    source $SCRIPTDIR/database.sh "sync"
  elif [[ $TOOLS_ACTION = "2" || $TOOLS_ACTION = "import" ]];then
    TOOLS_ACTION="import"
    source $SCRIPTDIR/requirements.sh
    source $SCRIPTDIR/database.sh "import"
  elif [[ $TOOLS_ACTION = "3" || $TOOLS_ACTION = "export" ]];then
    TOOLS_ACTION="export"
    source $SCRIPTDIR/requirements.sh
    source $SCRIPTDIR/database.sh "export"
  elif [ $TOOLS_ACTION = "4" ];then
    restore_backup
  elif [[ $TOOLS_ACTION = "5" || $TOOLS_ACTION = "pack_build" ]];then
    pack_build
  elif [[ $TOOLS_ACTION = "6" || $TOOLS_ACTION = "cleanup" ]];then
    cleanup_env
  elif [ $TOOLS_ACTION = "x" ];then
    exit 0
  else
    start_startscript
  fi
elif [ $TASK = "x" ];then
  exit 0
else
  start_startscript
fi



