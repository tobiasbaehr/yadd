#!/bin/bash

_quest_tools_env

if [[ "$BUILD_ENV" = "1" || "$BUILD_ENV" = "live" ]];then
  BUILD_ENV="live"
elif [[ "$BUILD_ENV" = "2" || "$BUILD_ENV" = "dev" ]];then
  BUILD_ENV="dev"
elif [[ "$BUILD_ENV" = "3" || "$BUILD_ENV" = "stage" ]];then
  BUILD_ENV="stage"
else
  incolor_red "Abbruch."
  exit 2
fi

_include_cfg_file
_set_alias_file

if [ -z $ALIASFILE ];then
  ALIASFILE="Die Alias-datei *.aliases.drushrc.php "
fi
if ! [ -f "$ALIASFILE" ];then
  if [ $TOOLS_ACTION = "export" ] || [ $TOOLS_ACTION = "sync" ];then
    incolor_red "$ALIASFILE ist nicht vorhanden, daher kann die Datenbank nicht exportiert/syncronisiert werden"
    exit 1
  fi
fi

if [[ $TOOLS_ACTION = "sync" || $TOOLS_ACTION = "export" ]];then
  cp $ALIASFILE $HOME/.drush/
  check_errs $?
  echo "$ALIASFILE nach $HOME/.drush/ kopiert."
  tmp=`basename $ALIASFILE`
  ALIASFILE="$HOME/.drush/$tmp"
fi

if [[ $TOOLS_ACTION = "sync" && ! $TOOLS_ACTION = "live" ]];then
  if [ -z $SYNC_USERNAME ];then
    echo "Wie lautet dein Remote-Username? Leerlassen, um den Namen des aktuellen eingeloggten User zu verwenden."
    read SYNC_USERNAME
  fi
  if [ -z $SYNC_USERNAME ];then
    SYNC_USERNAME=$USER
  fi
  sed -i "s/USERNAME_PLACEHOLDER/$SYNC_USERNAME/g" $ALIASFILE
  drush @$PROJECT.$BUILD_ENV sql-drop $VERBOSE
  drush sql-sync --structure-tables-key=$PROJECT @$PROJECT.live @$PROJECT.$BUILD_ENV $VERBOSE
  check_errs $?
  _install_modules
elif [ $TOOLS_ACTION = "export" ];then
  check_connection
  check_is_db_empty
  echo "Dateiname eingeben:"
  incolor_yellow  "(Leerlassen für Standardbezeichnung 'current_database')"
  read EXPORTNAME
  if [ -z $EXPORTNAME ];then
    EXPORTNAME="current_database";
  fi
  incolor_green "Beginne Export ..."
  drush @$PROJECT.$BUILD_ENV --structure-tables-key=$PROJECT sql-dump > $EXPORTNAME".sql" $VERBOSE
  check_errs $?
  gzip -9 $EXPORTNAME".sql"
  check_errs $?
  incolor_green "Beginne Export ... erledigt!"
elif [ $TOOLS_ACTION = "import" ];then
  select_database_name
  check_connection
  drush --root=$WWWPATH sql-drop $VERBOSE
  check_errs $?
  incolor_green "Beginne Import ..."
  gzip -dc ${DBEXPORTS_ARRAY[$NUMBER]} | `drush --root=$WWWPATH sql-connect`
  check_errs $?
  _install_modules
  incolor_green "Beginne Import ... erledigt!"
fi

