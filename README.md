Description
=========
[![Build Status](https://travis-ci.org/Yannik/ansible-role-rsnapshot-backup-host.svg?branch=master)](https://travis-ci.org/Yannik/ansible-role-rsnapshot-backup-host)

Make incremental backups securely using rsnapshot.

#### Why should backups always be pulled instead of being pushed?
Because pushing backups is highly [insecure](https://news.ycombinator.com/item?id=8621792).


Requirements
------------

[`rsnapshot-remote-host`](https://github.com/Yannik/ansible-role-rsnapshot-remote-host) must be installed on the hosts that should be backed up.

Role Variables
--------------

  * `rsnapshot_enable_cron`: whether to run backups automatically
      * Default: `False`
  * `rsnapshot_mailto`: where email reports should go to
  * `rsnapshot_custom_directives`: set custom `rsnapshot.conf` options
      * Currently supported options: `rsync_long_args`
  * `rsnapshot_backups`: List of backup sets
      * `name`: unique lowercase alphanumeric name (required)
      * `enabled`: yes/no
      * `interval`: how often should the data be synced (required)
          * options: `every30min, every1h, every3h, every6h, every12h, every24h`
      * `snapshot_root`: unique path where the backups will be saved (required)
      * `backup_host`: backupro@host from where the backups should be pulled from
      * `retain_settings`: list of backups that should be kept (required)
      * `backup_directives`: the actual list of directories that should be backed up (required)
          * `src`: Source directory (required)
          * `dest`: destination directory, by default the src path appended to `snapshot_root/`  (optional)
          * `args`: optional arguments
              * Example: `exclude=logs,exclude=vendor,+rsync_long_args=--bwlimit=625`


Example Playbook
----------------


    - hosts: all
      roles:
         - role: Yannik/rsnapshot-backup-host
           rsnapshot_enable_cron: True
           rsnapshot_mailto: test@example.org
           rsnapshot_custom_directives:
             rsync_long_args: --delete --numeric-ids --relative --delete-excluded --bwlimit=625
           rsnapshot_backups:
             - name: backups1
               interval: every30min
               snapshot_root: /var/rsnapshot-backups/backups1
               backup_host: backupro@example.org
               retain_settings:
                 - { name: every1h, keep: 12, cronjob: "30 * * * *" }
                 - { name: every1d, keep: 3, cronjob: "35 3 * * *" }
                 - { name: every1w, keep: 4, cronjob: "0 3 * * 1" }
               backup_directives:
                 - src: /etc
                 - src: /var/www
                   args: exclude=logs,exclude=vendor,+rsync_long_args=--bwlimit=625
                 - src: /usr/bin/ssh {{ rsnapshot_ssh_args }} backupro@example.org "sudo /etc/rsnapshot/backup-scripts/backup-mysql.sh"
                   type: script
                 - src: /var/rsnapshot-backup/mysqldump.sql.gz
             - name: backups2
               interval: every6h
               snapshot_root: /var/rsnapshot-backups/backups2
               backup_host: backupro@example2.org
               retain_settings:
                 - { name: every1d, keep: 3, cronjob: "35 3 * * *" }
                 - { name: every1w, keep: 4, cronjob: "0 3 * * 1" }
               backup_directives:
                 - src: /etc
                   dest: myetc

Inspired by
-------
  * [Backup remote Linux hosts without root access, using rsnapshot](http://dev.kprod.net/?q=linux-backup-rsnapshot-no-root)
  * [Restricting SSH Access to rsync](https://www.guyrutenberg.com/2014/01/14/restricting-ssh-access-to-rsync/)
  * [rsync as root with rrsync and sudo](https://www.v13.gr/blog/?p=216)
  * [Root, Sudo, and Rsnapshot](http://technokracy.net/2011/01/07/root_sudo_rsnapshot/)

License
-------

GPLv2

Author Information
------------------

Yannik Sembritzki
