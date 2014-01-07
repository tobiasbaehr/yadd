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
  incolor_red "Abbruch. Prozess wird beendet, da Drush nicht installiert ist."
  exit 2
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
