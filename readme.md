# Yet Another Drupal Deployment

### Kurzbeschreibung
Das vorliegende System soll das Deployment von Drupal-Projekten erleichtern und vereinheitlichen.

### Kompatiblität ###

Drush 5.x ist nicht mit Git 1.5.x kompatibel, da Drush-Make in Drush 5.x `git clone --mirror` verwendet.

### Schnellstart

- Projekt-Template kopieren

`cp -R ~/yadd/drupal_project_template/ ~/projectname_project && cd ~/projectname_project`

- Projekt-Informationen angeben

`nano config/common.cfg`

- Module in den Drush-Make-Files ergänzen

`nano base.make`

- Deploment-System aufrufen

`./setup.sh`

### Verzeichnisstruktur eines Projektes##
`/config` - Enthält die settings.php, {projektname}.aliases.drushrc.php, common.cfg etc.

`/libs` - Enthält alle externe Bibliotheken, die mit Hilfe der [Libraries API](http://drupal.org/project/libraries) genutzt werden können.

`base.make` - Enthält die Anweisungen für Drush-Make, die in der Umgebungen übereinstimmen.

`live.make` - Enthält die Anweisungen für Drush-Make, die nur in der Live-Umgebung nötig sind und bindet das Haupt Make-File ein. Beispiel Git-Repos nur in der Stabilen-Version.

`dev.make` - Enthält die Anweisungen für Drush-Make, die nur in der Dev-Umgebung nötig sind. Beispiel Git-Repos nur in der Dev-Version.

`/setup.sh` - Muss aufgerufen via Terminal, um das Deployment-System nutzen zu können.

`custom_builder.sh` Wird nach dem Drush-Make fertig ist, aufgerufen.

`custom_tasks_db.sh` Wird nach dem Importieren der Datenbank ausgeführt und kann z. B. genutzt wird, um Variablen zu setzen oder Module zu aktivieren/deaktivieren.

### Drush-Aliases-Datei
Diese Datei wird erst benötigt, wenn eine Datenbank exportiert bzw. von der Live-Umgebung importiert werden soll.

### Umgebungsabhängige Einstellungen ###
Jenach ausgewählter Umgebung, kann dafür eine seperate common.cfg, settings.php, custom_builder.sh bzw. custom_tasks_db.sh genutzt werden. Die nach dem Schema dev/live/stage.DATEI vorhanden sein muss.

### Systemabhängige Einstellungen ###
Alle Konfigurationdateien können je gewählter Umgebung überschrieben werden, wenn sie unter `~/.drupal_deployment/projectname_project/` gespeichert werden.

## Erläuterung der Aufgaben ##
Nach Aufruf der `setup.sh` Datei, werden verschieden Aufgaben aufgelistet. (Ansicht 1)

#### Ansicht 1

[1] *Live-Umgebung erstellen*

Besagt, erstelle mir ein Drupal, mit den Modulen, die in live.make + base.make enthalten sind.

[2] *Dev-Umgebung erstellen*

Besagt, erstelle mir ein Drupal, mit den Modulen, die in dev.make + base.make enthalten sind. + Devel, Schema, File Stage Proxy

[3] *Stage-Umgebung erstellen*

Besagt, erstelle mir ein Drupal, mit den Modulen, die in live.make + base.make enthalten sind. + File Stage Proxy

[5] *...weitere Aufgaben*

Wechselt zur Ansicht 2

[x] *Beenden*

Schließt die Anwendung

#### Ansicht 2 ####

[1] *Datenbank von Live importieren (SSH-Zugang erforderlich)**

Importiert die Datenbank vom Alias *live* in die gewählte Umgebung.

[2] *Lokale Datenbank importieren*

Importiert die ausgewählte Datenbank (bsp. current_database.sql.gz), die sich im Wurzelverzeichnis des Projektes befindet in die Datenbank der ausgewählten Umgebung.

[3] *Lokale Datenbank exportieren*

Exportiert die Datenbank der ausgewählten Umgebung und speichert sie in das Wurzelverzeichnis des Projektes.

[4] *Backup wiederherstellen*

Stellt die Drupal-Daten (Core, Contrib Module etc) sowie das `files` Verzeichnis wieder her und optinal auch die Datenbank für die ausgewählten Umgebung.

[5] *Aktuelles Build packen. (tar-Format und leerem sites/default Ordner)*

Erstellt ein Tar-Verzeichnis mit den Drupal-Daten ohne dem Order `sites/default` für ausgewählte Umgebung.

[6] *Umgebung bereinigen (Sudoer erforderlich, wenn keine Schreibrechte)*

Löscht das Verzeichnis [HTDOCS]\[PROJECT\]_sources und sowie den Symlink [HTDOCS]\[PROJECT\] für die ausgewählte Umgebung. Da der Apache-User Dateien erstellt im files Verzeichnis, fehlen hier ggf. die Rechte zum Löschen, daher muss man Sudoer sein.

### Verzeichnisstruktur der Drupal-Daten ###

Es erstellt unter [HTDOCS]\[PROJECT\]_sources die Ordner:

`/backups`

Backups der letzten 3 Builds.

`/builds`

Enthält das neueste Build ({projektname}_build_{YMD_HMS}), darauf zeigt ein Symbolischer Link ([HTDOCS]\[PROJECT\])

`/files`

Enthält die Dateien von Drupal, darauf zeigt ein Symbolischer Link ([[HTDOCS]\[PROJECT\]/[DRUPALFILESDIR])

`/libraries`

Enthält die Bibliotheken für Drupal, darauf zeigt ein Symbolischer Link ([HTDOCS]\[PROJECT\]/sites/all/libraries)









