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

  protected $htdocs = '';
  /**
   * Initialize $testproject.
   */
  function __construct() {
    parent::__construct();
    $this->testproject =  UNISH_SANDBOX . DS . $this->projectname;
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
    $root = $this->webroot() . DS . $this->projectname;
    #$root = $this->htdocs . DS . $this->projectname;
    $options = array('quiet' => NULL, 'yes' => TRUE, 'root' => $root);
    $this->drush($command, $args = array(), $options);
  }
  function createDummyProject() {
    @mkdir($this->testproject . DS . 'config', 0777, TRUE);
    $this->htdocs = UNISH_SANDBOX . DS . 'web';
    @mkdir($this->htdocs, 0777, TRUE);
    $data = "PROJECT={$this->projectname}\nHTDOCS={$this->htdocs}";
    file_put_contents($this->testproject . DS . 'config' . DS . 'common.ini', $data);
    $files = glob(dirname(__FILE__ ) . DS . 'testfiles' . DS . '*');
    foreach ($files as $file) {
      copy($file, $this->testproject . DS . basename($file));
    }
  }

  public function _copy_yadd() {
    $destination = getenv('HOME') . '/.drush/yadd';
    $dir = dirname(__FILE__) . DS . '..' . DS;
    $this->recurse_copy(realpath($dir), $destination);
  }

  function recurse_copy($src, $dst) {
    $dir = opendir($src);
    @mkdir($dst);
    while(false !== ( $file = readdir($dir)) ) {
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

  public function testYaddBuildEnvCommand() {
    $this->createDummyProject();
    $this->_copy_yadd();
    $command = 'yadd-build-env';
    $this->drush($command, $args = array(), $options = array('env' => 'dev', 'backup' => 'n', 'quiet' => NULL), $site_specification = NULL, $cd = $this->testproject);

    $root = $this->webroot() . DS . $this->projectname;

    $this->log(sprintf('Check is_link %s', $root), 'debug');
    $this->assertTrue(is_link($root), sprintf('%s is a symlink', $root));

    $dirs = array('', 'build', 'backups', 'files');
    foreach ($dirs as $dirname) {
      $dir = $this->htdocs . DS . $this->projectname . '_sources' . DS . $dirname;
      $this->log(sprintf('Check is_dir %s', $dir), 'debug');
      $this->assertTrue(is_dir($dir), sprintf('%s is a dir', $dir));
    }
    #$this->YaddExportLocalDBCommand();
  }

  public function testYaddExportLocalDBCommand() {
    $root = $this->webroot() . DS . $this->projectname;
    $env = 'default';
    $site = "$root/sites/$env";
    $options = array(
        'root' => $root,
        'db-url' => $this->db_url($env),
       # 'sites-subdir' => $env,
        'yes' => NULL,
        'quiet' => NULL,
    );
    $this->drush('site-install', array(NULL), $options);
    // Give us our write perms back.
    chmod($site, 0777);

    $command = 'yadd-export-local-db';
    $options = array('env' => 'dev', 'strict' => 0, 'quiet' => NULL);
    $this->drush($command, $args = array(), $options, $site_specification = NULL, $cd = $this->testproject);
    $backups = glob($this->testproject . DS . '*.sql.gz');
    #$this->log(print_r($backups), 'verbose');
    $this->assertEquals(1, count($backups));
sleep(2);
    $this->drush($command, $args = array(), $options + array('suffix' => 'mysuffix'), $site_specification = NULL, $cd = $this->testproject);
    $backups = glob($this->testproject . DS . '*.sql.gz');
   # $this->log(print_r($backups), 'verbose');
    $this->assertEquals(2, count($backups));
    $latest = end($backups);
    #$this->log($latest, 'verbose');
    $this->assertTrue(strpos($latest, 'mysuffix') !== FALSE);
    $this->sql_drop();
  }
}

/**
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
