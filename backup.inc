<?php

function yadd_create_backup() {
  $vars = yadd_build_vars();
  $env = yadd_get_env();
  $backup_name = implode('-', array($vars['PROJECT'], $vars['BUILD_DATE'], 'backup', $env)). '.tar';
  $new_backup = $vars['PROJECTBACKUPS'] . '/' . $backup_name;
  #drush_set_option('destination', $new_backup);
  $commandline_options = array(
    'root' => drush_get_option('root'),
    'destination' => $new_backup,
  );
  drush_invoke_process('@self', 'archive-backup', array(), $commandline_options);
  yadd_delete_backups();
  return;
}

function yadd_delete_backups() {
  $vars = yadd_build_vars();
  $max = $vars['MAX_BACKUPS'];
  $backup_dir = $vars['PROJECTBACKUPS'];
  $backup_files = glob($backup_dir. '/*.tar');
  $non_backup_files = glob($backup_dir. '/*', GLOB_ONLYDIR);
  if ($max > count($backup_files)) {
    return;
  }
  array_splice($backup_files, -1 * $max);
  $backup_files = array_merge($backup_files, $non_backup_files);
  foreach ($backup_files as $backup_file) {
    drush_op('drush_delete_tmp_dir', $backup_file);
  }
}