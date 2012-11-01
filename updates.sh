#!/bin/bash

run_update() {
  update_1
}
update_1() {
  if [ -d $PROJECTSOURCES/backup ];then
    mv $PROJECTSOURCES/backup/* $PROJECTSOURCES/backups/
    rmdir $PROJECTSOURCES/backup
  fi
}

