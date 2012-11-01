#!/bin/bash

DRUSH_TARGET="$HOME/drush"
DRUSH_CONTRIB="$HOME/.drush/"

GIT_VERSION=`git --version`
GIT_SUPPORTED=" 1.7"
GIT_17=`echo $GIT_VERSION | grep $GIT_SUPPORTED`

DRUSH_VERSION=`drush --version`
DRUSH_SUPPORTED="5.7"
DRUSH_5x=`echo $DRUSH_VERSION | grep $DRUSH_SUPPORTED`

incolor_yellow "Überprüfe Vorraussetzungen..."
if [ -z "$DRUSH_VERSION" ];then
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
  incolor_red "Abbruch. Prozess wird beendet, da $DRUSH_5x inkompatibel mit $GIT_VERSION ist."
  exit 2
fi
# Warnung, wenn git 1.7.x installiert ist und Drush 5.x nicht, wegen git clone --mirror in drush make
if [[ -z "$DRUSH_5x" && ! -z $GIT_17 ]];then
  incolor_yellow "Die Drush-Version ist veraltet, bitte auf $DRUSH_SUPPORTED Version aktualisieren."
  incolor_red "Abbruch. Prozess wird beendet, da Drush veraltet ist."
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


