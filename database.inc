<?php

function yadd_create_sql_dump($destination_dir = '') {
  $suffix = drush_get_option('suffix', NULL);
  $vars = yadd_build_vars();
  $filename = implode('-', array_filter(array('db', $vars['PROJECT'], $vars['BUILD_DATE'], $suffix))) . '.sql';
  drush_set_option('gzip', 1);
  drush_set_option('result-file', $filename);
  drush_invoke('sql-dump');

  $src_file = $vars['WWWDATA']. '/' . $filename . '.gz';
  $des_file = $destination_dir. '/' . $filename  . '.gz';
  if (file_exists($src_file)) {
    $moved = drush_move_dir($src_file, $des_file);
    if ($moved) {
      return $des_file;
    }
    else {
      return $src_file;
    }
  }
  return FALSE;
}

function yadd_import_sql_dump($source_dir = '') {
  if ($vars['BACKUP_PRE_IMPORT']) {
    drush_set_option('suffix', 'auto');
    $choice = drush_confirm(dt('Do you want to create a database backup?'));
    if ($choice == 'y') {
      drush_invoke('yadd-export-local-db');
    }
  }
  $pattern = '*.sql.gz';
  if ($source_dir) {
    $pattern = drush_trim_path($source_dir) . '/' . $pattern;
  }
  $dumps = glob($pattern);
  if (!empty($dumps)) {
    $files = array();
    foreach ($dumps as $dump) {
      $files[$dump] = $dump;
    }
    $file = drush_choice($files, 'Please select the dump');
    if (!empty($file)) {
      $tmpfile = drush_tempnam(basename($file));
      drush_copy_dir($file, $tmpfile, FILE_EXISTS_OVERWRITE);
      $compressed = $tmpfile . '.gz';
      drush_op('rename', $tmpfile, $compressed);
      $command = 'gzip --decompress %s';
      $return = drush_shell_cd_and_exec(dirname($compressed), $command, $compressed);
      if (!$return || !file_exists($tmpfile)) {
        return drush_set_error('YADDL_EXTRACT_SQL_DUMP_ERROR', dt('Unable to decompress !filename.', array('!filename' => $compressed)));
      }
      drush_invoke('sql-drop');
      drush_set_option('file', $tmpfile);
      drush_invoke('sql-query');
    }
  }
}
