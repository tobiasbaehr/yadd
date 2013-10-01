<?php
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
    $this->testproject =  UNISH_SANDBOX . DIRECTORY_SEPARATOR . $this->projectname;
  }

  /**
   * Runs after all tests in a class are run. Remove sandbox directory.
   */
  public static function tearDownAfterClass() {
    if (file_exists(UNISH_SANDBOX)) {
      yadd_file_delete_recursive(UNISH_SANDBOX);
    }
  }


  function createDummyProject() {
    @mkdir($this->testproject . DIRECTORY_SEPARATOR . 'config', 0777, TRUE);
    $this->htdocs = UNISH_SANDBOX . DIRECTORY_SEPARATOR . 'web';
    @mkdir($this->htdocs, 0777, TRUE);
    $data = "PROJECT={$this->projectname}\nHTDOCS={$this->htdocs}";
    file_put_contents($this->testproject . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'common.ini', $data);
    $files = glob(dirname(__FILE__ ) . DIRECTORY_SEPARATOR . 'testfiles' . DIRECTORY_SEPARATOR . '*');
    foreach ($files as $file) {
      copy($file, $this->testproject . DIRECTORY_SEPARATOR . basename($file));
    }
  }

   public static function setUpBeforeClass() {
     $sandbox = UNISH_SANDBOX;
     if (file_exists($sandbox)) {
       yadd_file_delete_recursive($sandbox);
     }
     parent::setUpBeforeClass();
   }

  public function _copy_yadd() {
    $destination = getenv('HOME') . '/.drush/yadd';
    $dir = dirname(__FILE__) . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR;
    $this->recurse_copy(realpath($dir), $destination);
  }

  function recurse_copy($src, $dst) {
    $dir = opendir($src);
    @mkdir($dst);
    while(false !== ( $file = readdir($dir)) ) {
      if (( $file != '.' ) && ( $file != '..' )) {
        if (is_dir($src . DIRECTORY_SEPARATOR . $file) ) {
          $this->recurse_copy($src . DIRECTORY_SEPARATOR . $file, $dst . DIRECTORY_SEPARATOR . $file);
        }
        else {
          copy($src . DIRECTORY_SEPARATOR . $file, $dst . DIRECTORY_SEPARATOR . $file);
        }
      }
    }
    closedir($dir);
  }

  public function testYaddBuildEnvCommand() {
    $this->createDummyProject();
    $this->_copy_yadd();
    $command = 'yadd-build-env';
    $this->drush($command, $args = array(), $options = array('env' => 'dev', 'backup' => 'n', 'quiet' => NULL), $site_specification = NULL, $cd = $this->testproject, $expected_return = self::EXIT_SUCCESS, $suffix = NULL, $env = NULL);

    $root = $this->webroot() . DIRECTORY_SEPARATOR . $this->projectname;

    $this->log(sprintf('Check is_link %s', $root), 'debug');
    $this->assertTrue(is_link($root), sprintf('%s is a symlink', $root));

    $dirs = array('', 'build', 'backups', 'files');
    foreach ($dirs as $dirname) {
      $dir = $this->htdocs . DIRECTORY_SEPARATOR . $this->projectname . '_sources' . DIRECTORY_SEPARATOR . $dirname;
      $this->log(sprintf('Check is_dir %s', $dir), 'debug');
      $this->assertTrue(is_dir($dir), sprintf('%s is a dir', $dir));
    }
  }

  public function testYaddExportLocalDBCommand() {
    $root = $this->webroot() . DIRECTORY_SEPARATOR . $this->projectname;
    $env = 'default';
    $site = "$root/sites/$env";
    $options = array(
        'root' => $root,
        'db-url' => $this->db_url($env),
        'sites-subdir' => $env,
        'yes' => NULL,
        'quiet' => NULL,
    );
    $this->drush('site-install', array(NULL), $options);
    // Give us our write perms back.
    chmod($site, 0777);

    $command = 'yadd-export-local-db';
    $this->drush($command, $args = array(), $options = array('env' => 'dev', 'strict' => 0, 'quiet' => NULL), $site_specification = NULL, $cd = $this->testproject, $expected_return = self::EXIT_SUCCESS, $suffix = NULL, $env = NULL);
    $this->assertEquals(1, count(glob($this->testproject . DIRECTORY_SEPARATOR . '*.sql.gz')));

    $this->drush($command, $args = array(), $options = array('env' => 'dev', 'strict' => 0, 'quiet' => NULL), $site_specification = NULL, $cd = $this->testproject, $expected_return = self::EXIT_SUCCESS, $suffix = NULL, $env = NULL);
    $this->assertEquals(2, count(glob($this->testproject . DIRECTORY_SEPARATOR . '*.sql.gz')));

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
    if (!yadd_file_delete_recursive($dir . DIRECTORY_SEPARATOR . $item)) {
      return FALSE;
    }
  }
  return rmdir($dir);
}
