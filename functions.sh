#!/bin/bash

function incolor_green {
  echo -e "\E[32;40m$1\E[0m" >&2
}

function incolor_red {
  echo -e "\E[31;40m$1\E[0m" >&2
}

function incolor_yellow {
  echo -e "\E[33;40m$1\E[0m" >&2
}

start_startscript() {
  ./$STARTSCRIPT
  exit 0
}

check_errs() {
  # Parameter 1 ist der return/exit code
  # Para. 2 ist der text, welches bei einem Fehler angezeigt werden soll
  if [ "${1}" -ne "0" ]; then
    if [ "${2}" != "" ]; then
      if [ "${1}" = 1 ]; then
        incolor_red "${2}"
      else
        incolor_yellow "${2}"
      fi
    fi
    # mit dem ursprünglichen exit code beenden.
    exit ${1}
  fi
}

select_database_name() {
  I=0
  DBEXPORTS=`find . -name \*.sql.gz`
  if [ -z "$DBEXPORTS" ];then
    incolor_red "Keine Daten zum Importieren gefunden"
    exit 1
  fi
  echo "Bitte DB-Export auswählen, das importiert werden soll:"
  for f in $DBEXPORTS
    do
      I=`expr $I + 1`
      DBEXPORTS_ARRAY[$I]=${f:2}
      echo "[$I] ${f:2}"
  done
  incolor_yellow "[x] Beenden"
  read NUMBER
  if [ -z "$NUMBER" ];then
    start_startscript
  elif [ $NUMBER = "x" ];then
    exit 0
  fi
}

check_connection() {
  #ist der root path eingetragen bzw. settings.php?
  dbconnection=`drush -q --root=$WWWPATH sql-connect`
  check_errs $? "Pfad zur Drupal-Installation (root) in der Alias-Datei ist inkorrekt."
}

check_is_db_empty() {
  #ist die db leer?
  usercount=`drush -q --root=$WWWPATH sql-query "SELECT COUNT(uid) FROM users"`
  check_errs $? "Datenbankverbindung in der settings.php ist inkorrekt oder nicht vorhandern oder Datenbank ist leer."
}

download_dev_modules() {
  drush --root=$(dirname $BUILD) --default-major=$MAJORVERSION --destination=$BUILD/sites/all/modules/contrib -y dl devel schema
}

install_dev_modules() {
  drush --root=$WWWPATH -y en devel schema
}

download_stage_file_proxy() {
  drush --root=$(dirname $BUILD) --default-major=$MAJORVERSION --destination=$BUILD/sites/all/modules/contrib -y dl stage_file_proxy
}

install_stage_file_proxy() {
  drush --root=$WWWPATH -y en stage_file_proxy
}

remove_symbolic_link() {
  if [ -h $WWWPATH ];then
    rm $WWWPATH
    check_errs $?
    echo "Alten Symboylischen Link für das Project entfernt."
  fi
  if [ -r $WWWPATH ];then
    incolor_red "$WWWPATH scheint ein Verzeichnis zu sein. Bitte umbenennen oder entfernen"
    exit 2
  fi
}

add_symbolic_link() {
  remove_symbolic_link
  ln -s $PROJECTBUILDS/$BUILD $WWWPATH
  echo "Neuen Symboylischen Link für das Project erstellt."
}

_build_env() {
  _include_cfg_file
  _check_project_env
  if [[ "$BUILD_ENV" = "stable"  ||  "$BUILD_ENV" = "stage" ]];then
    source $SCRIPTDIR/requirements.sh
    source $SCRIPTDIR/build.sh
  else
    source $SCRIPTDIR/requirements.sh
    source $SCRIPTDIR/build.sh
    #testing kann ruhig eine leere datenbank bekommen, die vorbereitet wird fürs
    #testen
    if [ $BUILD_ENV = "testing" ];then
    incolor_yellow "Beginne Datenbank-Einrichtung fürs Testen..."
      if [ $MAJORVERSION = "7" ] || [ $MAJORVERSION = "8" ];then
        drush --root=$WWWPATH si minimal
        drush --root=$WWWPATH en simpletest
      else
        drush --root=$WWWPATH si
        #simpletest installieren
        #patch anwenden
      fi
    incolor_green "Beginne Datenbank-Einrichtung fürs Testen...erledigt!"
    incolor_green "Zugangsdaten sind admin/admin"
    fi
  fi
}

cleanup_env() {
  _quest_tools_env
  _include_cfg_file
  
  incolor_yellow "Beginne Clean-Up ..."
  remove_symbolic_link
  if ! [ -w "$PROJECTSOURCES/sites/default" ];then
     sudo chmod -R 777 $PROJECTSOURCES
  fi
  sudo rm -rf $PROJECTSOURCES

  if [ -d $PROJECTSOURCES ];then
    incolor_red "Projectverzeichnisse konnte nicht gelöscht werden"
  else
    incolor_green "Beginne Clean-Up...erledigt!"
  fi
}
  
delete_backups() {
  MIN=3
  COUNT=`ls $PROJECTBACKUPS | wc -l`
  if ! [ "$COUNT" -gt "$MIN" ];then
    return
  fi
  DIFF=`expr $COUNT - $MIN`
  ALLFILES=`ls -tr $PROJECTBACKUPS | head -$DIFF`
  for CURRENTFILE in $ALLFILES
    do
      rm $PROJECTBACKUPS/$CURRENTFILE
      echo "$PROJECTBACKUPS/$CURRENTFILE wurde gelöscht."
    done
}
  
restore_backup() {
  _quest_tools_env
  _include_cfg_file
  
  I=0
  DIR=`pwd`
  cd $PROJECTBACKUPS
  BACKUPS=`find . -name \*.tar.gz`
  if [ -z "$BACKUPS" ];then
    incolor_red "Keine Backups gefunden"
    exit 1
  fi
  echo "Bitte Backup auswählen, das wiederhergestellt werden soll:"
  for f in $BACKUPS
    do
      I=`expr $I + 1`
      BACKUPS_ARRAY[$I]=${f:2}
      echo "[$I] ${f:2}"
  done
  incolor_yellow "[x] Beenden"

  read NUMBER
  if [ -z "$NUMBER" ];then
    cd $DIR
    start_startscript
  elif [ $NUMBER = "x" ];then
    cd $DIR
    exit 0
  fi
  BACKUPFILE=${BACKUPS_ARRAY[$NUMBER]}
  BACKUPDIR=${BACKUPFILE%.tar.gz}
  echo "Entpacke Backup..."
  tar -xzf $BACKUPFILE
  
  echo "Entferne $PROJECTSOURCES/files..."
  sudo rm -rf $PROJECTSOURCES/files
  check_errs $?
  
  echo "Verschiebe $BACKUPDIR/files nach $PROJECTSOURCES"
  mv $BACKUPDIR/files $PROJECTSOURCES
  chmod -R 777 $PROJECTFILES

  echo "Entferne $PROJECTSOURCES/libs"
  rm -rf $PROJECTSOURCES/libs
  
  echo "Verschiebe $BACKUPDIR/libs nach $PROJECTSOURCES"
  mv $BACKUPDIR/libs $PROJECTSOURCES
  LIST=`ls $BACKUPDIR`
  for f in $LIST
  do
    if [ -d $BACKUPDIR/$f ];then
      buildname=$f
      rm -rf $PROJECTBUILDS/$f
      echo "Verschiebe $BACKUPDIR/$f nach $PROJECTBUILDS"
      mv $BACKUPDIR/$f $PROJECTBUILDS
    elif [ -f $BACKUPDIR/$f ];then
      echo "Soll die Datenbank wiederhergestellt werden? (y/n)"
      read RESTORE_DB_Y_N
      if [ $RESTORE_DB_Y_N = "y" ];then
        drush --root=$WWWPATH sql-drop
        echo "Entpacke Datenbank $BACKUPDIR/$f und importiere sie"
        gzip -dc $BACKUPDIR/$f | `drush --root=$WWWPATH sql-connect`
      fi
    fi
  done
  echo "Lösche $BACKUPDIR"
  rm -rf $BACKUPDIR
  add_symbolic_link $buildname
}

_create_backup() {
  if [ -f $WWWPATH/index.php ];then
    if [ -z "$BACKUP_PRE_BUILD" ];then
      incolor_yellow "Die folgende Abfrage kann automatisiert werden, wenn die Einstellungen in der Konfigurationsdatei $PROJECTCONFIG gesetzt wird. (BACKUP_PRE_BUILD=y)"
    fi
    if [ -z "$BACKUP_PRE_BUILD" ];then
      echo "Soll ein Backup der Datenbank sowie der Dateien erstellt werden? (y/n)"
      read BACKUP_PRE_BUILD
    fi
    if [ "$BACKUP_PRE_BUILD" = "y" ];then
	    incolor_yellow "Erstelle Backup ..."
	      DIR=`pwd`
	      cd $PROJECTBACKUPS
	      NEW_BACKUP="backup_vom_$DATUM"
	      mkdir $NEW_BACKUP
	      incolor_yellow "Erstelle Datenbank-Backup für $WWWPATH ..."
	      sqlname="db_backup_vom_$DATUM.sql"
	      drush --root=$WWWPATH sql-dump > $sqlname
	      check_errs $?
	      gzip -9 $sqlname
	      mv "$sqlname.gz" $PROJECTBACKUPS/$NEW_BACKUP
	      incolor_green "Erstelle Datenbank-Backup für $WWWPATH ...erledigt"
	      check_errs $?
	      cp -R $PROJECTFILES $PROJECTBACKUPS/$NEW_BACKUP
	      cp -R $PROJECTLIBS $PROJECTBACKUPS/$NEW_BACKUP
	      cd $PROJECTBUILDS
	      BUILDNAME=`basename $EXPANDED_WWWPATH`
	      cp -R $PROJECTBUILDS/$BUILDNAME $PROJECTBACKUPS/$NEW_BACKUP
	      cd $PROJECTBACKUPS
	      tar -czf $NEW_BACKUP".tar.gz" $NEW_BACKUP
	      rm -rf $NEW_BACKUP
	      cd $DIR
	      check_errs $?
	      echo "Backup von $WWWPATH unter $PROJECTBACKUPS/backup_vom_$DATUM.tar.gz gespeichert"
	      delete_backups
	    incolor_green "Erstelle Backup ...erledigt!"
    else
      incolor_yellow "Es wird kein Backup erstellt."
    fi
  fi
}

_check_project_env() {
  incolor_yellow "Überprüfe Project-Dateistruktur..."
  if ! [ -w $HTDOCS ];then
    incolor_yellow "Keine Schreibrechte für $HTDOCS ?"
    exit 2
  fi
  if ! [ -d $PROJECTSOURCES ];then
    mkdir -pv $PROJECTSOURCES
    check_errs $?
  fi
  
  if ! [ -d $PROJECTBACKUPS ];then
    mkdir -pv $PROJECTBACKUPS
    check_errs $?
  fi
  
  if ! [ -d $PROJECTBUILDS ];then
    mkdir -pv $PROJECTBUILDS
    check_errs $?
  fi
  
  if ! [ -d $PROJECTLIBS ];then
    mkdir -pv $PROJECTLIBS
    check_errs $?
  fi
  
  if ! [ -d $PROJECTFILES ];then
    mkdir -pv -m 777 $PROJECTFILES
    check_errs $?
  fi
  incolor_green "Überprüfe Project-Dateistruktur...erledigt!"
}

pack_build() {
  _quest_tools_env
  _include_cfg_file
  DIR=`pwd`
  ARCHIVNAME="$PROJECT""_""$DATUM.tar.gz"
  if [ ! -d $PROJECTBUILDS ];then
    incolor_red "Verzeichnis $PROJECTBUILDS konnte nicht gefunden werden."
    exit 1
  else
    cd $PROJECTBUILDS
  fi
  BUILD=`ls -tr`
  if [ -d "$BUILD" ]; then
    tar --exclude="sites/default/files" --exclude=".drupal_deployment_env" --exclude="sites/default/settings.php" --exclude-vcs -cvhzf $ARCHIVNAME "$BUILD"
    cd $DIR
    mv $PROJECTBUILDS/$ARCHIVNAME .
  else
    incolor_red "Build konnte nicht gefunden werden."
    exit 1
  fi
}

_include_cfg_file() {
  # the global build env config file
  tmp="config/$BUILD_ENV.common.cfg";
  if [ -f $tmp ]; then
    PROJECTCONFIG=$tmp
    source $tmp
  fi
  # project specific user config file
  tmp="$DD_SETTINGS/common.cfg";
  if [ -f $tmp ]; then
    PROJECTCONFIG=$tmp
    source $tmp
  fi
  # build env specific user config file
  tmp="$DD_SETTINGS/$BUILD_ENV.common.cfg";
  if [ -f $tmp ]; then
    PROJECTCONFIG=$tmp
    source $tmp
  fi
  _create_vars
}

function _include_common_cfg_file() {
  # the global config file
  PROJECTCONFIG="config/common.cfg";
  if [ -f $PROJECTCONFIG ]; then
    source $PROJECTCONFIG
  else
     incolor_red "$PROJECTCONFIG nicht gefunden. Diese muss mindesten die PROJECT=myproject Anweisung enthalten."
     exit 2 
  fi
}

function _create_vars() {
  if [ -z $HTDOCS ];then
    HTDOCS="/var/www/"
  fi
  WWWPATH=$HTDOCS$PROJECT
  EXPANDED_WWWPATH=`readlink $WWWPATH`
  PROJECTSOURCES=$WWWPATH"_sources"
  PROJECTBACKUPS=$PROJECTSOURCES/backups
  PROJECTBUILDS=$PROJECTSOURCES/builds
  PROJECTLIBS=$PROJECTSOURCES/libs
  PROJECTFILES=$PROJECTSOURCES/files
  DATUM=$(date +"%Y%m%d_%H%M%S")
  DD_ENV="$WWWPATH/.drupal_deployment_env"
  if [ -z $DRUPALFILESDIR ];then
    DRUPALFILESDIR="sites/default/files"
  fi
  if [ -z $MAJORVERSION ];then
    MAJORVERSION=7
  fi
  CURRENT_BUILD_ENV=""
  if [ -f $DD_ENV ]; then
    CURRENT_BUILD_ENV=`cat $DD_ENV`
  fi
}

function _set_settings_file() {
  # custom path in cfg file?
  if ! [ -z $SETTINGS_FILE ];then
    exit 0
  fi
  # the global settings file
  tmp="config/settings.php";
  if [ -f $tmp ]; then
    SETTINGS_FILE=$tmp
  fi
  # the global build env settings file
  tmp="config/$BUILD_ENV.settings.php";
  if [ -f $tmp ]; then
    SETTINGS_FILE=$tmp
  fi
  # project specific user settings file
  tmp="$DD_SETTINGS/settings.php";
  if [ -f $tmp ]; then
    SETTINGS_FILE=$tmp
  fi
  # build env specific user settings file
  tmp="$DD_SETTINGS/$BUILD_ENV.settings.php";
  if [ -f $tmp ]; then
    SETTINGS_FILE=$tmp
  fi
  if [ -z $SETTINGS_FILE ];then
    SETTINGS_FILE="$BUILD/sites/default/default.settings.php"
  fi
}

function _set_alias_file() {
  # custom path in cfg file?
  if ! [ -z $ALIASFILE ];then
    exit 0
  fi
  # the global aliases file
  tmp="config/$PROJECT.aliases.drushrc.php";
  if [ -f $tmp ]; then
    ALIASFILE=$tmp
  fi
  # project specific user aliases file
  tmp="$DD_SETTINGS/$PROJECT.aliases.drushrc.php";
  if [ -f $tmp ]; then
    ALIASFILE=$tmp
  fi
}

function _install_modules() {
  if [ ! -z $CURRENT_BUILD_ENV ] && [ $CURRENT_BUILD_ENV = "dev" ];then
    install_dev_modules
  fi
  if [ $CURRENT_BUILD_ENV = "dev" ] || [ $CURRENT_BUILD_ENV = "stage" ];then
    install_stage_file_proxy
    if [ ! -z $REMOTE_URL ];then
      drush --root=$WWWPATH -y vset stage_file_proxy_origin $REMOTE_URL
      _include_custom_tasks_after_db_import
    fi
  fi
}

function _quest_tools_env() {
  if [ -z "$TOOLS_ENV" ];then
    clear
    echo "Bitte Umgebung angeben:"
    echo "[1]Live-Umgebung"
    echo "[2]Dev-Umgebung"
    echo "[3]Stage-Umgebung"
    incolor_yellow "[x] Beenden"
    read BUILD_ENV
    if [ $BUILD_ENV = "1" ];then
      BUILD_ENV="live"
    elif [ $BUILD_ENV = "2" ];then
      BUILD_ENV="dev"
    elif [ $BUILD_ENV = "3" ];then
      BUILD_ENV="stage"
    fi
  else
    BUILD_ENV=$TOOLS_ENV
  fi
  if [ $BUILD_ENV = "x" ];then
    start_startscript
  fi
}

function _include_custom_builder_file() {
  # the global config file
  CUSTOMBUILDER_FILE=""
  tmp="custom_builder.sh";
  if [ -f $tmp ]; then
    CUSTOMBUILDER_FILE=$tmp
  fi
  # the global build env config file
  tmp="$BUILD_ENV.custom_builder.sh";
  if [ -f $tmp ]; then
    CUSTOMBUILDER_FILE=$tmp
  fi
  # project specific user config file
  tmp="$DD_SETTINGS/$PROJECT.custom_builder.sh";
  if [ -f $tmp ]; then
    CUSTOMBUILDER_FILE=$tmp
  fi
  # build env specific user config file
  tmp="$DD_SETTINGS/$BUILD_ENV.$PROJECT.custom_builder.sh";
  if [ -f $tmp ]; then
    CUSTOMBUILDER_FILE=$tmp
  fi
  if [ ! -z $CUSTOMBUILDER_FILE ] && [ -f $CUSTOMBUILDER_FILE ];then
    source $CUSTOMBUILDER_FILE
  fi
}

function _include_custom_tasks_after_db_import() {
  # the global tasks file
  CUSTOMTASKS_FILE=""
  tmp="custom_tasks_db.sh";
  if [ -f "$tmp" ]; then
    CUSTOMTASKS_FILE=$tmp
  fi
  # the global build env config file
  tmp="$BUILD_ENV.custom_tasks_db.sh";
  if [ -f "$tmp" ]; then
    CUSTOMTASKS_FILE=$tmp
  fi
  # project specific user config file
  tmp="$DD_SETTINGS/$PROJECT.custom_tasks_db.sh";
  if [ -f "$tmp" ]; then
    CUSTOMTASKS_FILE=$tmp
  fi
  # build env specific user config file
  tmp="$DD_SETTINGS/$BUILD_ENV.$PROJECT.custom_tasks_db.sh";
  if [ -f "$tmp" ]; then
    CUSTOMTASKS_FILE=$tmp
  fi
  if [ ! -z "$CUSTOMTASKS_FILE" ] && [ -f "$CUSTOMTASKS_FILE" ];then
    source $CUSTOMTASKS_FILE
  fi
}
