<?php

/**
 * @file
 * Aliases file for drush.
 */

$project = 'myproject';

$st = array(
  'structure-tables' => array(
    $project => array(
      'batch',
      'cache_field',
      'cache_bootstrap',
      'cache',
      'cache_filter',
      'cache_form',
      'cache_menu',
      'cache_page',
      'cache_path',
      'cache_update',
      'history',
      'sessions',
      'watchdog',
    ),
  ),
);

$aliases['dev'] = array(
  'path-aliases' => array(
    '%dump' => "/tmp/$project-local.sql",
  ),
  'command-specific' => array(
    'sql-sync' => array(
      'simulate' => '0',
      'no-cache' => TRUE,
    ),
  ),
  'databases' => array(
    'default' => array(
      'default' => array(
        'database' => $project . '_dev',
        'username' => 'root',
        'password' => 'root',
        'host' => 'localhost',
        'port' => '',
        'driver' => 'mysql',
        'prefix' => '',
      ),
    ),
  ),
);
$aliases['dev'] += $st;
$aliases['dev']['command-specific']['sql-sync'] += $st;

$aliases['stage'] = array(
  'path-aliases' => array(
    '%dump' => "/tmp/$project-stage.sql",
  ),
  'command-specific' => array(
    'sql-sync' => array(
      'simulate' => '0',
      'no-cache' => TRUE,
    ),
  ),
  'databases' => array(
    'default' => array(
      'default' => array(
        'database' => $project . '_stage',
        'username' => 'root',
        'password' => 'root',
        'host' => 'localhost',
        'port' => '',
        'driver' => 'mysql',
        'prefix' => '',
      ),
    ),
  ),
);
$aliases['stage'] += $st;
$aliases['stage']['command-specific']['sql-sync'] += $st;

// USERNAME_PLACEHOLDER nicht ändern
$aliases['live'] = array(
  'remote-host' => '$PLACEHOLDER',
  'remote-user' => 'USERNAME_PLACEHOLDER',
  'path-aliases' => array(
    '%dump' => "/tmp/$project-live.sql",
    '%files' => 'sites/default/files',
  ),
  'command-specific' => array(
    'sql-sync' => array(
      'simulate' => '1',
      'no-cache' => TRUE,
    ),
    'rsync' => array(
      'simulate' => '1',
    ),
  ),
  'databases' => array(
    'default' => array(
      'default' => array(
        'database' => $project . '_live',
        'username' => '$PLACEHOLDER',
        'password' => '$PLACEHOLDER',
        'host' => 'localhost',
        'port' => '',
        'driver' => 'mysql',
        'prefix' => '',
      ),
    ),
  ),
);
