#!/bin/bash

if [ $1 = "drush" ];then
  if ! [ -z $GIT_17 ]; then
    wget -O $HOME/drush.zip http://ftp.drupal.org/files/projects/drush-7.x-5.4.zip
  else
    wget -O $HOME/drush.zip http://ftp.drupal.org/files/projects/drush-All-versions-4.x-dev.zip
  fi
  if [ -f $HOME/drush.zip ];then
    unzip $HOME/drush.zip -d $HOME
    check_errs $? "Druch konnte nicht nach $HOME entpackt werden."
    chmod 777 $DRUSH_TARGET/drush
    if ! [ -d $HOME/bin ];then
      mkdir $HOME/bin
    fi
    ln -s $DRUSH_TARGET/drush $HOME/bin/drush
    rm $HOME/drush.zip
    # set PATH so it includes user's private bin if it exists
    if [ -d "$HOME/bin" ] ; then
      PATH="$HOME/bin:$PATH"
    fi
  else
    incolor_red "Abbruch. Drush konnte nicht nach $HOME heruntergeladen werden."
    exit 2
  fi
elif [ $1 = "drushmake" ];then
  wget -O $HOME/drushmake.zip http://ftp.drupal.org/files/projects/drush_make-6.x-2.3.zip
  if [ -f $HOME/drushmake.zip ];then
    unzip $HOME/drushmake.zip -d $DRUSH_CONTRIB
    if ! [ -d $DRUSH_CONTRIB/drush_make ]
    then
      incolor_red "Abbruch. Drush Make konnte nicht entpackt werden."
      exit 2
    fi
  else
    incolor_red "Abbruch. Drush Make konnte nicht nach $HOME heruntergeladen werden."
    exit 2
  fi
fi

