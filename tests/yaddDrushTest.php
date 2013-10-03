<?php
if (!defined('DS')) {
  define('DS', DIRECTORY_SEPARATOR);
}

/*
 * @file
 *   PHPUnit Tests for YADD. This uses Drush's own test framework, based on PHPUnit.
 */
class yaddCase extends Drush_CommandTestCase {

  protected $testproject;

  protected $projectname = 'myproject';

  protected $root = '';

  protected $sources = '';

  /**
   * Initialize $testproject, $root.
   */
  function __construct() {
    parent::__construct();
    $this->testproject =  UNISH_SANDBOX . DS . $this->projectname;
    $this->root = $this->webroot() . DS . $this->projectname;
    $this->sources = $this->webroot() . DS . $this->projectname . '_sources';
  }

  public static function setUpBeforeClass() {
    $sandbox = UNISH_SANDBOX;
    if (file_exists($sandbox)) {
      yadd_file_delete_recursive($sandbox);
    }
    parent::setUpBeforeClass();
  }

  /**
   * Runs after all tests in a class are run. Remove sandbox directory.
   */
  public static function tearDownAfterClass() {
    if (file_exists(UNISH_SANDBOX)) {
      yadd_file_delete_recursive(UNISH_SANDBOX);
    }
  }

  public function sql_drop() {
    $command = 'sql-drop';
    $options = array('quiet' => NULL, 'yes' => TRUE, 'root' => $this->root);
    $this->drush($command, $args = array(), $options);
  }

  function createDummyProject($common_data = NULL, $env_data = array()) {
    @mkdir($this->testproject . DS . 'config', 0777, TRUE);
    @mkdir($this->webroot(), 0777, TRUE);
    if (empty($common_data)) {
      $common_data = "PROJECT={$this->projectname}\nHTDOCS={$this->webroot()}";
    }
    file_put_contents($this->testproject . DS . 'config' . DS . 'common.ini', $common_data);
    $files = glob(dirname(__FILE__ ) . DS . 'testfiles' . DS . '*');
    foreach ($files as $file) {
      copy($file, $this->testproject . DS . basename($file));
    }
    if (!empty($env_data)) {
      foreach ($env_data as $env => $data) {
        file_put_contents($this->testproject . DS . 'config' . DS . $env . '.config.ini', $data);
      }
    }
  }

  public function _copy_yadd() {
    $destination = getenv('HOME') . DS. '.drush' . DS . 'yadd';
    $dir = dirname(__FILE__) . DS . '..' . DS;
    $this->recurse_copy(realpath($dir), $destination);
  }

  function recurse_copy($src, $dst) {
    $dir = opendir($src);
    @mkdir($dst);
    while (false !== ( $file = readdir($dir)) ) {
      if (( $file != '.' ) && ( $file != '..' )) {
        if (is_dir($src . DS . $file) ) {
          $this->recurse_copy($src . DS . $file, $dst . DS . $file);
        }
        else {
          copy($src . DS . $file, $dst . DS . $file);
        }
      }
    }
    closedir($dir);
  }

  function install_drupal($env = 'default') {
    $site = "{$this->root}/sites/default";
    $options = array(
      'root' => $this->root,
      'db-url' => $this->db_url($env),
      'yes' => NULL,
      'quiet' => NULL,
    );
    $this->drush('site-install', array(NULL), $options);
    // Give us our write perms back.
    chmod($site, 0777);
    $settings_php = $this->root . DS . 'sites' . DS . 'default' . DS . 'settings.php';
    $this->log(sprintf('Check is_file %', $settings_php), 'debug');
    $this->assertTrue(is_file($settings_php));
    $this->_checkDrupalStatus();
  }

  public function _buildEnvDefaultTests() {
    $this->log(sprintf('Check is_link %s', $this->root), 'debug');
    $this->assertTrue(is_link($this->root), sprintf('%s is a symlink', $this->root));

    $dirs = array('', 'build', 'backups', 'files');
    foreach ($dirs as $dirname) {
      $dir = $this->sources . DS . $dirname;
      $this->log(sprintf('Check is_dir %s', $dir), 'debug');
      $this->assertTrue(is_dir($dir), sprintf('%s is a dir', $dir));
    }
  }

  public function _checkDrupalStatus($status = self::EXIT_SUCCESS) {
    $options = array('root' => $this->root, 'quiet' => NULL);
    $this->drush('status', $args = array(), $options, NULL, NULL, $status);
  }

  public function testYaddBuildEnvCommand() {
    $this->createDummyProject();
    $this->_copy_yadd();
    $command = 'yadd-build-env';
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->_buildEnvDefaultTests();
    $this->install_drupal();

    $common_data = "PROJECT={$this->projectname}\nHTDOCS={$this->webroot()}\nBACKUP_PRE_BUILD='y'";
    $this->createDummyProject($common_data);

    copy($this->root . DS . 'sites' . DS . 'default' . DS . 'settings.php', $this->testproject . DS . 'config'. DS . 'settings.php');
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->_buildEnvDefaultTests();
    $this->_checkDrupalStatus();

    $pattern = $this->sources . DS . 'backups' . DS . '*.tar';
    $backups = glob($pattern);
    $this->assertEquals(1, count($backups));

    $this->createDummyProject();
    copy($this->testproject . DS . 'config'. DS . 'settings.php', $this->testproject . DS . 'config'. DS . 'dev.settings.php');
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->_buildEnvDefaultTests();
    $this->_checkDrupalStatus();
  }

  public function testYaddBackupEnvCommand() {
    $command = 'yadd-backup-env';
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $pattern = $this->sources . DS . 'backups' . DS . '*.tar';
    $backups = glob($pattern);
    $this->assertEquals(2, count($backups));

    // Wait 2 seconds to avoid that every 2 second run fails.
    #sleep(2);

    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $backups = glob($pattern);
    $this->assertEquals(3, count($backups));
  }

  public function testYaddRestoreBackupCommand() {
    $this->sql_drop();
    $this->assertTrue(is_link($this->root));
    yadd_file_delete_recursive($this->root);
    $this->assertFalse(is_link($this->root));

    $backups = glob($this->sources . DS . 'backups' . DS .'*.tar');
    $backup_file = reset($backups);
    $command = 'yadd-restore-backup';
    $options = array('env' => 'dev', 'backup-file' => $backup_file, 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->assertTrue(is_link($this->root));
    $this->_checkDrupalStatus();
  }

  public function testYaddExportLocalDBCommand() {
    $command = 'yadd-export-local-db';
    $options = array('env' => 'dev', 'strict' => 0, 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $backups = glob($this->testproject . DS . '*.sql.gz');
    $this->assertEquals(1, count($backups));

    // Wait 2 seconds to avoid that every 2 second run fails.
    sleep(2);

    $this->drush($command, $args = array(), $options + array('suffix' => 'mysuffix'), $site_specification = NULL, $cd = $this->testproject);
    $backups = glob($this->testproject . DS . '*.sql.gz');
    $this->assertEquals(2, count($backups));
    $latest = end($backups);
    $this->assertTrue(strpos($latest, 'mysuffix') !== FALSE);
  }

  public function testYaddImportLocalDBCommand() {
    $command = 'yadd-import-local-db';
    $db_backups = glob($this->testproject . DS . '*.gz');
    // We set here 'yes' so that drush do want a confirmation.
    $options = array('env' => 'dev', 'db-file' => reset($db_backups), 'yes' => NULL, 'strict' => 0, 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->_checkDrupalStatus();
    $common_data = "PROJECT={$this->projectname}\nHTDOCS={$this->webroot()}\nBACKUP_PRE_IMPORT='y'";
    $this->createDummyProject($common_data);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->_checkDrupalStatus();

    $db_backups = glob($this->testproject . DS . '*.gz');
    $this->assertEquals(3, count($db_backups));
    $latest = end($db_backups);
    $this->assertTrue(strpos($latest, 'auto') !== FALSE);
  }

  public function testYaddCleanUpEnvCommand() {
    $command = 'yadd-cleanup-env';
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);

    $this->log(sprintf('Check is_link %s is FALSE', $this->root), 'debug');
    $this->assertFalse(is_link($this->root), sprintf('%s is not a symlink', $this->root));

    $this->log(sprintf('Check is_dir %s is FALSE', $this->sources), 'debug');
    $this->assertFalse(is_dir($this->sources), sprintf('%s is not a dir', $this->sources));
  }

  public function testYaddCleanUpAllCommand() {
    yadd_file_delete_recursive($this->testproject);
    $this->createDummyProject();
    $command = 'yadd-build-env';
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->install_drupal();
    $this->_buildEnvDefaultTests();

    $htdocs = $this->webroot() . 'live';
    @mkdir($htdocs, 0777);
    $this->createDummyProject(NULL, array('live' => "HTDOCS=$htdocs"));
    $options = array('env' => 'live', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);

    $this->root = $htdocs . DS . $this->projectname;
    $this->sources = $htdocs . DS . $this->projectname . '_sources';
    $this->install_drupal('live');
    $this->_buildEnvDefaultTests();

    $command = 'yadd-cleanup-all';
    $options = array('quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);

    clearstatcache();
    $this->log(sprintf('Check is_link %s is FALSE', $this->root), 'debug');
    $this->assertFalse(is_link($this->root), sprintf('%s is not a symlink', $this->root));

    $this->log(sprintf('Check is_dir %s is FALSE', $this->sources), 'debug');
    $this->assertFalse(is_dir($this->sources), sprintf('%s is not a dir', $this->sources));

    $this->root = $this->webroot() . DS . $this->projectname;
    $this->sources = $this->webroot() . DS . $this->projectname . '_sources';

    $this->log(sprintf('Check is_link %s is FALSE', $this->root), 'debug');
    $this->assertFalse(is_link($this->root), sprintf('%s is not a symlink', $this->root));

    $this->log(sprintf('Check is_dir %s is FALSE', $this->sources), 'debug');
    $this->assertFalse(is_dir($this->sources), sprintf('%s is not a dir', $this->sources));
  }
}

/**
 * Fixed version of drush_file_delete_recursive() in Drush 5.x.
 *
 * Same code as drush_delete_dir().
 * @see drush_delete_dir()
 *
 * @param string $dir
 * @return boolean
 */
function yadd_file_delete_recursive($dir) {
  // Do not delete symlinked files, only unlink symbolic links
  if (is_link($dir)) {
    return unlink($dir);
  }
  // Allow to delete symlinks even if the target doesn't exist.
  if (!is_link($dir) && !file_exists($dir)) {
    return TRUE;
  }
  @chmod($dir, 0777); // Make file/dir writeable
  if (!is_dir($dir)) {
    return unlink($dir);
  }
  foreach (scandir($dir) as $item) {
    if ($item == '.' || $item == '..') {
      continue;
    }
    if (!yadd_file_delete_recursive($dir . DS . $item)) {
      return FALSE;
    }
  }
  return rmdir($dir);
}
