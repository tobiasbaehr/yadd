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

  /**
   * Initialize $testproject, $root.
   */
  function __construct() {
    parent::__construct();
    $this->testproject =  UNISH_SANDBOX . DS . $this->projectname;
    $this->root = $this->webroot() . DS . $this->projectname;
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

  function createDummyProject($common_data = NULL) {
    @mkdir($this->testproject . DS . 'config', 0777, TRUE);
    #$this->htdocs = UNISH_SANDBOX . DS . 'web';
    @mkdir($this->webroot(), 0777, TRUE);
    if (empty($common_data)) {
      $common_data = "PROJECT={$this->projectname}\nHTDOCS={$this->webroot()}";
    }
    file_put_contents($this->testproject . DS . 'config' . DS . 'common.ini', $common_data);
    $files = glob(dirname(__FILE__ ) . DS . 'testfiles' . DS . '*');
    foreach ($files as $file) {
      copy($file, $this->testproject . DS . basename($file));
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

  function install_drupal() {
    $env = 'default';
    $site = "{$this->root}/sites/$env";
    $options = array(
      'root' => $this->root,
      'db-url' => $this->db_url($env),
      'yes' => NULL,
      'quiet' => NULL,
    );
    $this->drush('site-install', array(NULL), $options);
    // Give us our write perms back.
    chmod($site, 0777);
  }

  public function testYaddBuildEnvCommand() {
    $this->createDummyProject();
    $this->_copy_yadd();
    $command = 'yadd-build-env';
    $this->drush($command, $args = array(), $options = array('env' => 'dev', 'backup' => 'n', 'quiet' => NULL), $site_specification = NULL, $cd = $this->testproject);
    $this->log(sprintf('Check is_link %s', $this->root), 'debug');
    $this->assertTrue(is_link($this->root), sprintf('%s is a symlink', $this->root));

    $dirs = array('', 'build', 'backups', 'files');
    foreach ($dirs as $dirname) {
      $dir = $this->webroot() . DS . $this->projectname . '_sources' . DS . $dirname;
      $this->log(sprintf('Check is_dir %s', $dir), 'debug');
      $this->assertTrue(is_dir($dir), sprintf('%s is a dir', $dir));
    }
  }

  public function testYaddExportLocalDBCommand() {
    $this->install_drupal();
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

  public function testYaddBackupEnvCommand() {
    $command = 'yadd-backup-env';
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $pattern = $this->webroot() . DS . $this->projectname . '_sources' . DS . 'backups' . DS . '*.tar';
    $backups = glob($pattern);
    $this->log($pattern, 'notice');
    $this->assertEquals(1, count($backups));

    // Wait 2 seconds to avoid that every 2 second run fails.
    #sleep(2);

    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $backups = glob($pattern);
    $this->assertEquals(2, count($backups));
  }

  public function testYaddRestoreBackupCommand() {
    $this->sql_drop();
    $this->assertTrue(is_link($this->root));
    yadd_file_delete_recursive($this->root);
    $this->assertFalse(is_link($this->root));

    $backups = glob($this->webroot() . DS . $this->projectname . '_sources' . DS . 'backups' . DS .'*.tar');
    $backup_file = reset($backups);
    $command = 'yadd-restore-backup';
    $options = array('env' => 'dev', 'backup-file' => $backup_file, 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $this->assertTrue(is_link($this->root));
    $options = array('quiet' => TRUE, 'root' => $this->root);
    $this->drush('status', $args = array(), $options, $site_specification = NULL);

  }

  public function testYaddCleanUpEnvCommand() {
    $command = 'yadd-cleanup-env';
    $options = array('env' => 'dev', 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);

    $this->assertFalse(is_link($this->root), sprintf('%s is not a symlink', $this->root));
    #$this->log($this->getOutput(), 'verbose');
    $dir = $this->webroot() . DS . $this->projectname . '_sources';
    $this->log(sprintf('Check is_dir %s is FALSE', $dir), 'debug');
    $this->assertFalse(is_dir($dir), sprintf('%s is not a dir', $dir));
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
