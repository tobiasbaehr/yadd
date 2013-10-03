<?php

function yadd_build_env() {
  $vars = yadd_build_vars();
  if ($vars['BACKUP_PRE_BUILD'] == 'y') {
    drush_invoke('yadd-backup-env');
  }
  drush_log('Begin building process ...', 'status');
  $env = yadd_get_env();
  $BUILD = $vars['BUILD_DATE'];
  $project_dir = yadd_get_project_dir();
  if ($env == 'dev') {
    drush_invoke_process('@self', 'make', array('dev.make', $BUILD), array('working-copy', 'no-gitinfofile'));
    if (drush_op('is_dir', $BUILD)) {
      yadd_download_dev_modules($BUILD, array('devel', 'schema'));
    }
  }
  else{
    drush_invoke_process('@self', 'make', array($env.'.make', $BUILD));
  }
  if ($env !== 'live') {
    yadd_download_dev_modules($BUILD, array('stage_file_proxy'));
  }
  $settings_file = yadd_get_settings_file($BUILD);
  if (!file_exists($settings_file)) {
    return drush_set_error('YADD_SETTINGS_FILE_NOT_FOUND', 'Could not found a settings.php file.');
  }
  $dst = "$BUILD/sites/default/settings.php";
  drush_copy_dir($settings_file, $dst);
  drush_log(dt('Copy %src to %dst', array('%src' => $settings_file, '%dst' => $dst)), 'info');

  drush_move_dir("$BUILD/robots.txt", "$BUILD/robots.bak");
  drush_shell_exec("rm $BUILD/*.txt");
  drush_move_dir("$BUILD/robots.bak", "$BUILD/robots.txt");
  drush_log('Removed all unnecessary text files.', 'info');

  $libs = $project_dir . '/libs';
  _yadd_delete_lib();
  if (drush_op('is_dir', $libs)) {
    $files = glob($libs . '/*');
    $filecount = count($files);
    if ($filecount > 0) {
      drush_copy_dir($libs, $vars['PROJECTLIBS']);
      drush_log(dt('Copy the directory %src to %dst', array('%src' => $libs, '%dst' =>  $vars['PROJECTLIBS'])), 'info');
    }
  }

  _yadd_move_lib_dir($BUILD);

  if (drush_op('is_dir', $vars['PROJECTFILES'])) {
    drush_op('symlink', $vars['PROJECTFILES'], $BUILD . '/' . $vars['DRUPAL_FILES_DIR']);
    drush_log('Created symlink for the files directory', 'info');
  }
  $BUILD_DESTINATION = $vars['PROJECTBUILD'] . '/' . $BUILD;
  drush_move_dir($BUILD, $BUILD_DESTINATION);
  $linked = yadd_add_symbolic_link_to_build($BUILD_DESTINATION);

  if ($linked) {
    _yadd_delete_old_build();
    drush_log('Finished building process...completed', 'success');
    return TRUE;
  }
  return FALSE;
}

/**
 * Deletes the old build.
 */
function _yadd_delete_old_build() {
  $vars = yadd_build_vars();
  $project_build_dir = $vars['PROJECTBUILD'];
  $build_dirs = glob($project_build_dir. '/*');
  // Remove the latest build from the stack.
  array_pop($build_dirs);
  foreach ($build_dirs as $build_dir) {
    drush_op('drush_delete_tmp_dir', $build_dir);
  }
}

function yadd_add_symbolic_link_to_build($BUILD_DESTINATION) {
  $removed = yadd_remove_symbolic_link_from_build();
  if (empty($removed)) {
    return FALSE;
  }
  $vars = yadd_build_vars();
  drush_op('symlink', $BUILD_DESTINATION, $vars['WWWDATA']);
  if (drush_op('is_link', $vars['WWWDATA'])) {
    drush_log('Added symlink to the project.', 'info');
    return TRUE;
  }
  return drush_set_error('YADD_BUILD_ADD_SYMLINK', dt('Could not link path %path to %dst', array('%path' => $vars['WWWDATA'], '%dst' => $BUILD_DESTINATION)));
}

function yadd_remove_symbolic_link_from_build() {
  $vars = yadd_build_vars();
  #drush_log(print_r($vars, 1), 'status');
  if (drush_op('is_link', $vars['WWWDATA'])) {
    drush_op('unlink', $vars['WWWDATA']);
    if (!drush_op('is_link', $vars['WWWDATA'])) {
      drush_log('Removed old symlink from the project.', 'info');
      return TRUE;
    }
    else{
      return drush_set_error('YADD_BUILD_REMOVE_SYMLINK', dt('Could not unlink path %path', array('%path' => $vars['WWWDATA'])));
    }
  }
  else if (drush_op('is_dir', $vars['WWWDATA'])) {
    return drush_set_error('YADD_BUILD_IS_DIR', dt('%dir is a directory. Rename it or remove it.', array('%dir' => $vars['WWWDATA'])));
  }
  return TRUE;
}

function _yadd_move_lib_dir($BUILD) {
  $vars = yadd_build_vars();
  drush_mkdir($vars['PROJECTLIBS']);
  $existing_lib = "$BUILD/sites/all/libraries";
  if (drush_op('is_dir', $existing_lib)) {
    $files = glob($existing_lib . '/*');
    if (!empty($files)) {
      foreach ($files as $file) {
        drush_move_dir($file, drush_trim_path($vars['PROJECTLIBS']) . '/' . basename($file));
      }
    }
  }
  drush_delete_tmp_dir($existing_lib);
  if (drush_op('is_dir', $vars['PROJECTLIBS'])) {
    drush_op('symlink', $vars['PROJECTLIBS'], $existing_lib);
    drush_log('Created symlink for the libraries directory', 'info');
  }
}

function _yadd_delete_lib() {
  $vars = yadd_build_vars();
  if (drush_op('is_dir', $vars['PROJECTLIBS'])) {
    drush_delete_tmp_dir($vars['PROJECTLIBS']);
    drush_log(dt('Deleted libraries directory %dir.', array('%dir' => $vars['PROJECTLIBS'])), 'info');
  }
}

function _yadd_move_files_dir($BUILD) {
  $vars = yadd_build_vars();
  drush_delete_tmp_dir($vars['PROJECTFILES']);
  $dir = $BUILD . '/' . $vars['DRUPAL_FILES_DIR'];
  drush_move_dir($dir, $vars['PROJECTFILES']);
  drush_delete_tmp_dir($dir);
  if (drush_op('is_dir', $vars['PROJECTFILES'])) {
    drush_op('symlink', $vars['PROJECTFILES'], $dir);
    drush_log('Created symlink for the files directory', 'info');
  }
}