<?php
/**
 * @file
 * Drush wrapper around the YADD.
 */

require_once __DIR__ . '/common.inc';

define('COMMON_CONFIG_FILE', 'config/common.ini');

/**
 * Implements hook_drush_command().
 */
function yadd_drush_command() {
  $default_options = array(
    'env' => 'The environment such like dev, stage, live etc.',
  );
  $items['yadd'] = array(
    'description' => 'Choose a YADD command',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
  );
  $items['yadd-build-env'] = array(
    'description' => 'Build a drupal environment.',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options,
  );
  $items['yadd-backup-env'] = array(
    'description' => 'Create a backup of the drupal environment',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options,
  );
  $items['yadd-restore-backup'] = array(
    'description' => 'Restore a backup for a drupal environment',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options,
  );
  $items['yadd-export-local-db'] = array(
    'description' => 'Export the database of the drupal environment',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options + array('suffix' => 'Suffix to the filename. E.g. db-myproject-20130829_173810-mysuffix.sql.gz'),
  );
  $items['yadd-import-local-db'] = array(
    'description' => 'Import the database to the drupal environment',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options,
  );
  $items['yadd-package-env'] = array(
    'description' => 'Build a tar archive of a the drupal environment',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options + array(
      'exclude' => 'Comma seperated list of files, directories to exclude this from the package. Default: sites/default/files, sites/default/settings.php',
    ),
  );
  $items['yadd-cleanup-env'] = array(
    'description' => 'Deletes all known files of a the drupal environment',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options,
  );
  $items['yadd-cleanup-all'] = array(
    'description' => 'Deletes all known files of all environments',
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH,
    'options' => $default_options,
  );
  return $items;
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd() {
  drush_shell_exec('clear');
  $commands = yadd_drush_command();
  unset($commands['yadd']);
  $tasks = array();
  foreach ($commands as $key => $command) {
    $tasks[$key] = $command['description'];
  }
  $choice = drush_choice($tasks, 'Enter the number to use the task.');
  if (!empty($choice)) {
    drush_invoke($choice);
  }
  return;
}

/**
 * Implements drush_COMMAND_validate().
 */
function drush_yadd_build_env_validate() {
  $check = yadd_check_requirements();
  if (empty($check)) {
    return;
  }
  yadd_check_env_option();
  $vars = yadd_build_vars();
  if (!drush_op('is_writable', $vars['HTDOCS'])) {
    drush_set_error('YADD_HTDOCS_IS_NOT_WRITABLE', dt('The htdocs directory (%dir) is not writable', array('%dir' => $vars['HTDOCS'])));
    return FALSE;
  }
  $env = yadd_get_env();
  $project_dir = yadd_get_project_dir();
  $make_file = "$project_dir/$env.make";
  if (!drush_op('file_exists', $make_file)) {
    drush_set_error('YADD_MAKE_FILE_NOT_AVAILABLE', dt('The make file (%file) is not available', array('%file' => $make_file)));
    return FALSE;
  }
  drush_mkdir($vars['PROJECTSOURCES'], TRUE);
  drush_mkdir($vars['PROJECTBACKUPS'], TRUE);
  drush_mkdir($vars['PROJECTBUILD'], TRUE);
  # drush_mkdir($vars['PROJECTLIBS'], TRUE);
  drush_mkdir($vars['PROJECTFILES'], TRUE);
  return -1;
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_build_env() {
  require_once __DIR__ . '/build.inc';
  yadd_build_env();
}

/**
 * Implements drush_COMMAND_validate().
 */
function drush_yadd_backup_env_validate() {
  $check = yadd_check_requirements();
  if (empty($check)) {
    return;
  }
  yadd_check_env_option();
  $vars = yadd_build_vars();
  drush_mkdir($vars['PROJECTBACKUPS'], TRUE);
  $files = glob($vars['WWWDATA'] . '/*');
  if (empty($files)) {
    return drush_set_error('YADD_BACKUP_ERRO', 'Did not found any files to backup.');
  }
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_backup_env() {
  require_once __DIR__ . '/backup.inc';
  yadd_create_backup();
}

/**
 * Implements drush_COMMAND_validate().
 */
function drush_yadd_export_local_db_validate() {
  return yadd_check_env_option();
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_export_local_db() {
  require_once __DIR__ . '/database.inc';
  $dir = yadd_get_project_dir();
  yadd_create_sql_dump($dir);
}

/**
 * Implements drush_COMMAND_validate().
 */
function drush_yadd_import_local_db_validate() {
  yadd_check_env_option();
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_import_local_db() {
  require_once __DIR__ . '/database.inc';
  $dir = yadd_get_project_dir();
  yadd_import_sql_dump($dir);
}

/**
 * Implements drush_COMMAND_validate().
 */
function drush_yadd_restore_backup_validate() {
  yadd_check_env_option();
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_restore_backup() {
  $vars = yadd_build_vars();
  $backups = glob($vars['PROJECTBACKUPS'] . '/*.tar');
  if (empty($backups)) {
    return drush_log('Could not found a backup.', 'warning');
  }
  $tmp = array();
  foreach ($backups as $backup) {
//     $pattern = '/(\d){8}_(\d){6}/';
//     preg_match($pattern, $backup, $matches);
//     drush_print_r($matches);
    $tmp[$backup] = $backup;
  }
  $backups = $tmp;
  unset($tmp);
  $choice = drush_choice($backups, 'Choose the backup to restore.');
  if (!empty($choice)) {
    #drush_set_option('file', $choice);
    #drush_set_option('destination', $vars['PROJECTBUILD'] . '/' . $vars['BUILD_DATE']);
    $destination = $vars['PROJECTBUILD'] . '/' . $vars['BUILD_DATE'];
    $commandline_options = array(
      #'root' => $vars['WWWDATA'],
      'destination' => $destination,
    );
    $success = drush_invoke_process('@self', 'archive-restore', array('file' => $choice), $commandline_options);
    if ($success) {
      require_once __DIR__ . '/build.inc';
      _yadd_delete_lib();
      _yadd_move_lib_dir($destination);
      _yadd_move_files_dir($destination);
      yadd_add_symbolic_link_to_build($destination);
      _yadd_delete_old_build();
    }
  }
}

/**
 * Implements drush_COMMAND_validate().
 */
function drush_yadd_package_env_validate() {
  yadd_check_env_option();
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_package_env() {
  drush_log('Begin package process ...', 'status');
  $vars = yadd_build_vars();
  $builds = glob($vars['PROJECTBUILD'] . '/*');
  $build = reset($builds);
  $env = yadd_get_env();
  $package_name = implode('-', array($vars['PROJECT'], $vars['BUILD_DATE'], 'package', $env)). '.tar.gz';
  if (!drush_op('is_dir', $build)) {
    return drush_set_error('YADD_PACKAGE_ERROR', 'Could not create package');
  }
  $exclude_list = explode(',', drush_get_option('exclude', 'sites/default/files,sites/default/settings.php'));
  $exclude_list = array_map('trim', $exclude_list);
  $exclude = '';
  if (!empty($exclude_list)) {
    $exclude = ' --exclude=' . implode(' --exclude=', $exclude_list);
  }
  $tar = drush_get_tar_executable();
  $success = drush_shell_exec("$tar $exclude --exclude-vcs -cvhzf $package_name $build");
  if ($success) {
    drush_log('Finished package process...completed', 'success');
  }
  else{
    return drush_set_error('YADD_PACKAGE_ERROR', 'Could not create package. Add the option -d to see more information.');
  }
}

/**
 * Implements drush_COMMAND_validate().
 */
function drush_yadd_cleanup_env_validate() {
  yadd_check_env_option();
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_cleanup_env() {
  drush_log('Begin cleanup process ...', 'status');
  $root = drush_get_option('root', NULL);
  $del1 = drush_op('drush_delete_tmp_dir', $root);
  $vars = yadd_build_vars();
  $del2 = drush_op('drush_delete_tmp_dir', $vars['PROJECTSOURCES']);
  if ($del1 && $del2) {
    drush_log('Finished cleanup process...completed', 'success');
  }
}

/**
 * Implements drush_COMMAND().
 */
function drush_yadd_cleanup_all() {
  $envs = yadd_get_env_list();
  foreach ($envs as $key => $label) {
    yadd_set_env('env', $key);
    drush_invoke('yadd-cleanup-env');
  }
}



