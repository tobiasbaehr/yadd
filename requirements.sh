#!/bin/bash

DRUSH_TARGET="$HOME/drush"
DRUSH_CONTRIB="$HOME/.drush/"

GIT_VERSION_STRING=`git --version`
GIT_VERSION=${GIT_VERSION_STRING:12}
GIT_SUPPORTED="1.7"
if [ "$GIT_VERSION" \> "$GIT_SUPPORTED" ];then
  GIT_17=$GIT_VERSION
fi

DRUSH_VERSION_STRING=`drush --version`
DRUSH_VERSION=${DRUSH_VERSION_STRING:14}
DRUSH_SUPPORTED="5.0"
if [ "$DRUSH_VERSION" \> "$DRUSH_SUPPORTED" ];then
  DRUSH_5x=$DRUSH_VERSION
fi

incolor_yellow "Überprüfe Vorraussetzungen..."
if [ -z "$DRUSH_VERSION_STRING" ];then
  incolor_red "Drush ist nicht installiert."
  echo "Soll Drush installiert werden? (y/n)"
  read INSTALL_DRUSH
  if [ $INSTALL_DRUSH = "y" ];then
    source $SCRIPTDIR/install.sh "drush"
  else
    incolor_yellow "Drush wird nicht installiert."
    incolor_red "Abbruch. Prozess wird beendet, da Drush nicht installiert ist."
    exit 2
  fi
fi

# Warnung, wenn Drush 5.x installiert ist, jedoch git 1.7.x nicht, wegen git clone --mirror in drush make
if [[ ! -z "$DRUSH_5x" && -z $GIT_17 ]];then
  incolor_red "Abbruch. Prozess wird beendet, da $DRUSH_VERSION_STRING inkompatibel mit $GIT_VERSION_STRING ist."
  exit 2
fi
# Warnung, wenn git 1.7.x installiert ist und Drush 5.x nicht, wegen git clone --mirror in drush make
if [[ -z "$DRUSH_5x" && ! -z $GIT_17 ]];then
  incolor_red "Abbruch. Prozess wird beendet, da $GIT_VERSION_STRING inkompatibel mit $DRUSH_VERSION_STRING ist."
  exit 2
fi
#Drush make nicht installieren bei drush 5.x, da bereits enthalten
if [[ -z "$DRUSH_5x" && ! -d "$DRUSH_CONTRIB/drush_make" ]];then
  incolor_red "Drush Make ist nicht unter $DRUSH_CONTRIB/drush_make installiert."
  echo "Soll Drush Make installiert werden? (y/n)" >&2
  read INSTALL_DRUSH_MAKE
  if [ $INSTALL_DRUSH_MAKE = "y" ];then
    source $SCRIPTDIR/install.sh "drushmake"
  else
    incolor_yellow "Drush Make wird nicht installiert."
    incolor_red "Abbruch. Prozess wird beendet, da Drush Make nicht installiert ist."
    exit 2
  fi
fi

if ! [ -d $DRUSH_CONTRIB ];then
  mkdir $DRUSH_CONTRIB
fi

if ! [ -d $DRUSH_TARGET ];then
  DRUSH_TARGET_BIN=`which drush`
  if [ -h $DRUSH_TARGET_BIN ];then
    DRUSH_TARGET=`readlink $DRUSH_TARGET_BIN`
  else
    DRUSH_TARGET=$DRUSH_TARGET_BIN
  fi
    DRUSH_TARGET=`dirname $DRUSH_TARGET`
fi

incolor_green "Überprüfe Vorraussetzungen...erledigt."


