<?php

function yadd_get_env_list() {
  $envs = array();
  $pattern = array('dev', 'stage', 'live');
  foreach ($pattern as $env) {
    $filename = $env . '.make';
    if (file_exists($filename)) {
      $envs[$env] = strtoupper($env);
    }
  }
  return $envs;
}

function yadd_download_dev_modules($BUILD, $modules = array()) {
  $vars = yadd_build_vars();
  $commandline_options = array(
    'root' => dirname($BUILD),
    'default-major' => $vars['MAJORVERSION'],
    'destination' => $BUILD . '/sites/all/modules/contrib',
    'interactive' => 1,
  );
  $commandline_args = array_merge($modules, array('-y'));
  drush_invoke_process('@none', 'dl', $commandline_args, $commandline_options);
}

function yadd_get_settings_file($BUILD) {
  $vars = yadd_build_vars();
  if (!empty($vars['SETTINGS_FILE'])) {
    return $vars['SETTINGS_FILE'];
  }
  $env = yadd_get_env();
  $project_dir = yadd_get_project_dir();
  $files[] = "$project_dir/custom_config/$env.settings.php";
  $files[] = "$project_dir/custom_config/settings.php";
  $files[] = "$project_dir/config/$env.settings.php";
  $files[] = "$project_dir/config/settings.php";
  foreach ($files as $filename) {
    if (file_exists($filename)) {
      return $filename;
    }
  }
  return "$BUILD/sites/default/default.settings.php";
}

function yadd_build_vars($reset = FALSE) {
  static $vars = array();
  if (empty($vars) || $reset) {
    $vars['HTDOCS'] = '/var/www';
    $vars['MAJORVERSION'] = '7';
    $vars['DRUPAL_FILES_DIR'] = 'sites/default/files';
    $vars['BUILD_DATE'] = date('Ymd_His');
    $vars['MAX_BACKUPS'] = 3;
    $vars['BACKUP_PRE_BUILD'] = 'n';
    $vars['BACKUP_PRE_IMPORT'] = 'n';
    $vars = array_merge($vars, yadd_get_common_project_data());
    $vars = array_merge($vars, yadd_get_config_file_data());

    $vars['WWWDATA'] = $vars['HTDOCS'] . '/' . $vars['PROJECT'];
    $source = $vars['PROJECTSOURCES'] = $vars['WWWDATA'] . '_sources';
    $vars['PROJECTBACKUPS'] = "$source/backups";
    $vars['PROJECTBUILD'] = "$source/build";
    $vars['PROJECTLIBS'] = "$source/libs";
    $vars['PROJECTFILES'] = "$source/files";
  }
  return $vars;
}

/**
 * Helper function to get the environment via option --env or via select list.
 *
 * @return boolean
 */
function yadd_check_env_option() {
  drush_shell_exec('clear');
  $env_option = drush_get_option('env');
  if (!empty($env_option)) {
    yadd_set_env($env_option);
  }
  $env = yadd_get_env();
  if (empty($env)) {
    $env = yadd_select_env_for_task('%env', 'Choose the environment');
  }
  if (empty($env)) {
    drush_set_error('YADD_UNKNOWN_ENV', dt('Could not detect the environment.'));
    return FALSE;
  }
  $vars = yadd_build_vars();
  if (is_link($vars['WWWDATA'])) {
    drush_set_option('root', readlink($vars['WWWDATA']));
    drush_set_context('DRUSH_DRUPAL_ROOT', readlink($vars['WWWDATA']));
  }
 # drush_print_r(readlink($vars['WWWDATA']));
  yadd_set_env($env);
}

function yadd_check_requirements() {
  $config_file = yadd_get_common_config_file();
  if (!file_exists($config_file)) {
    drush_set_error('YADD_COMMON_CONFIG_FILE_NOT_FOUND', dt('Could not found %file.', array('%file' => $config_file)));
    return FALSE;
  }
  $project_data = yadd_get_common_project_data();
  if (empty($project_data)) {
    drush_set_error('YADD_COMMON_CONFIG_FILE_EMPTY', dt('Config file %file is empty.', array('%file' => $config_file)));
    return FALSE;
  }
  if (empty($project_data['PROJECT'])) {
    drush_set_error('YADD_COMMON_CONFIG_FILE_PROJECT_EMPTY', dt('Projectname is not set in %file.', array('%file' => $config_file)));
    return FALSE;
  }
  return -1;
}

function yadd_set_project_dir($wd = NULL) {
  static $working_dir = NULL;
  if (empty($working_dir)) {
    $working_dir = getcwd();
    if (!empty($wd)) {
      $working_dir = $wd;
    }
  }
  return $working_dir;
}

function yadd_get_project_dir() {
  return yadd_set_project_dir();
}

function yadd_select_env_for_task($title = '%env-environment', $question = '', $addtional_choices = array()) {
  $envs = yadd_get_env_list();
  $choices = array();
  foreach ($envs as $env => $env_title) {
    $choices[$env] = dt($title, array('%env' => $env_title));
  }
  $choices = array_merge($choices, $addtional_choices);
  $choice = drush_choice($choices, $question);
  if (isset($envs[$choice])) {
    yadd_set_env($choice);
  }
  return $choice;
}

function yadd_set_env($env = NULL, $reset = FALSE) {
  static $local_env = NULL;
  if (is_null($local_env) || $reset) {
    $local_env = $env;
  }
  return $local_env;
}

function yadd_get_env() {
  return yadd_set_env();
}

function yadd_get_common_config_file() {
  $wd = yadd_get_project_dir();
  return $wd . '/'. COMMON_CONFIG_FILE;
}

function yadd_get_common_project_data() {
  $settings = parse_ini_file(yadd_get_common_config_file());
  if (!empty($settings)) {
    return $settings;
  }
  return array();
}

function yadd_get_config_file() {
  $env = yadd_get_env();
  $project_dir = yadd_get_project_dir();
  $files[] = "$project_dir/custom_config/$env.config.ini";
  $files[] = "$project_dir/custom_config/config.ini";
  $files[] = "$project_dir/config/$env.config.ini";
  foreach ($files as $filename) {
    if (file_exists($filename)) {
      return $filename;
    }
  }
  return NULL;
}

function yadd_get_config_file_data() {
  $config_file = yadd_get_config_file();
  if (empty($config_file)) {
    return array();
  }
  $settings = parse_ini_file($config_file);
  if (!empty($settings)) {
    return $settings;
  }
  return array();
}
