#!/bin/bash
_create_backup

incolor_yellow "Beginne neue Zusammenstellung ..."
  BUILD="$PROJECT"_build_"$DATUM"
  NO_GITINFOFILE=""
  if [ ! -z "$DRUSH_5x" ];then
    NO_GITINFOFILE="--no-gitinfofile"
  fi
  if [ $BUILD_ENV = "dev" ];then 
      drush make $VERBOSE --working-copy $NO_GITINFOFILE "dev".make $BUILD
      if [ -d $BUILD ];then
        download_dev_modules
      fi
  else
      drush make $VERBOSE "live".make $BUILD
  fi
  if ! [ -d $BUILD ];then
    incolor_red "Abbruch. Build $BUILD konnte nicht erstellt werden."
    exit 2;
  fi
  #stage_file_proxy ist sowohl in dev als auch stage nützlich
  if [[ $BUILD_ENV = "stage" || $BUILD_ENV = "dev" ]];then
    download_stage_file_proxy
  fi
  #nützlich für das automatische installieren von modulen
  echo $BUILD_ENV > $BUILD"/.drupal_deployment_env"
  
  _set_settings_file
  if [ ! -z $SETTINGS_FILE ] && [ -f $SETTINGS_FILE ];then
    echo "Kopiere settings.php"
    cp $SETTINGS_FILE $BUILD/sites/default/settings.php
  else
    incolor_yellow "Konnte keine settings.php finden."
  fi

  #robots.txt umbenennen, um das Löschen im nächsten Schritt zu vermeiden
  if [ -f $BUILD/robots.txt ];then
    mv $BUILD/robots.txt $BUILD/robots.bak
    echo "Entferne alle unnötige Textdateien"
    rm $BUILD/*".txt"
    mv $BUILD/robots.bak $BUILD/robots.txt
  fi
  
  if [[ -d "libs" && "$(ls -A libs)" ]];then
   rm -rf "$PROJECTLIBS"/*
   check_errs $? "Die Dateien innerhalb des Verzeichnisses $PROJECTLIBS konnten nicht gelöscht werden."
   cp -R "libs"/* "$PROJECTLIBS"
   check_errs $? "Die Dateien innerhalb des Verzeichnisses libs konnten nicht nach $PROJECTLIBS kopiert werden."
   echo "Kopiere Dateien für das libraries-Verzeichnis"
  fi
  _include_custom_builder_file
  # when a libraries folder is already available, then move the files and delete dir
  tmp="$BUILD/sites/all/libraries"
  if [ -d "$tmp" ];then
     cp -R "$tmp"/* "$PROJECTLIBS"
     rm -rf "$tmp"
  fi
  ln -s "$PROJECTLIBS" "$BUILD/sites/all/libraries"
  echo "Symboylischen Link für das libraries-Verzeichnis erstellt."
  ln -s "$PROJECTFILES" "$BUILD/$DRUPALFILESDIR"
  echo "Symboylischen Link für das files-Verzeichnis erstellt."
  mv -f "$BUILD" "$PROJECTBUILDS"
  echo "Neuestes Projectbuild ins Projectbuilds-Verzeichnis verschoben."

incolor_green "Beginne neue Zusammenstellung...erledigt!"

add_symbolic_link

PROJECTBUILDS_LIST=`ls -A $PROJECTBUILDS`
for CURRENT_BUILD in $PROJECTBUILDS_LIST
do
  if [ "$CURRENT_BUILD" != "$BUILD" ];then
    if ! [ -w "$PROJECTBUILDS/$CURRENT_BUILD/sites/default" ];then
      sudo rm -rf "$PROJECTBUILDS/$CURRENT_BUILD"
    else
      rm -rf "$PROJECTBUILDS/$CURRENT_BUILD"
    fi
    echo "Build $CURRENT_BUILD entfernt."
  fi
done
incolor_green "Prozess beendet."

