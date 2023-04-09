Description
=========
[![Build Status](https://travis-ci.org/Yannik/ansible-role-rsnapshot-backup-host.svg?branch=master)](https://travis-ci.org/Yannik/ansible-role-rsnapshot-backup-host)

Make incremental backups securely using rsnapshot.

#### Why should backups always be pulled instead of being pushed?
Because pushing backups is highly [insecure](https://news.ycombinator.com/item?id=8621792).


Requirements
------------

[`Yannik/rsnapshot-remote-host`](https://github.com/Yannik/ansible-role-rsnapshot-remote-host) must be installed on the hosts that should be backed up.

Role Variables
--------------

  * `rsnapshot_enable_cron`: whether to run backups automatically
      * Default: `true`
  * `rsnapshot_mailto`: where email reports should go to
  * `rsnapshot_custom_options`: set custom `rsnapshot.conf` options (list of dicts as some options can be used multiple times)
  * `rsnapshot_backups`: List of backup sets
      * `name`: unique lowercase alphanumeric name (required)
      * `enabled`: yes/no
      * `interval`: how often should the data be synced (required)
          * options: `every30min, every1h, every3h, every6h, every12h, every24h`
      * `snapshot_root`: unique path where the backups will be saved (required)
      * `backup_host`: backupro@host from where the backups should be pulled from
      * `retain_settings`: list of backups that should be kept (required)
      * `maxdowntime`: maximum time a host is allowed to be down (format: 6h, 12d)
      * `custom_options`: custom options (list of dicts as some options can be used multiple times)
      * `backup_directives`: the actual list of directories that should be backed up (required)
          * `src`: Source directory (required)
          * `dest`: destination directory, by default the src path appended to `snapshot_root/`  (optional)
          * `args`: optional arguments
              * Example: `exclude=logs,exclude=vendor,+rsync_long_args=--bwlimit=625`


Example Playbook
----------------


    - hosts: all
      roles:
         - role: yannik.rsnapshot-backup-host
           rsnapshot_enable_cron: True
           rsnapshot_mailto: test@example.org
           rsnapshot_custom_directives:
             - rsync_long_args: --delete --numeric-ids --relative --delete-excluded --bwlimit=625
           rsnapshot_backups:
             - name: backups1
               interval: every30min
               snapshot_root: /var/rsnapshot-backups/backups1
               backup_host: backupro@example.org
               retain_settings:
                 - { name: every1h, keep: 12 }
                 - { name: every1d, keep: 3 }
                 - { name: every1w, keep: 4 }
               backup_directives:
                 - src: /etc
                 - src: /var/www
                   args: exclude=logs,exclude=vendor,+rsync_long_args=--bwlimit=625
                 - src: "sudo /etc/rsnapshot/backup-scripts/backup-mysql.sh"
                   type: ssh
                 - src: /var/rsnapshot-backup/mysqldump.sql.gz
             - name: backups2
               interval: every6h
               snapshot_root: /var/rsnapshot-backups/backups2
               backup_host: backupro@example2.org
               retain_settings:
                 - { name: every1d, keep: 3 }
                 - { name: every1w, keep: 4 }
               backup_directives:
                 - src: /etc
                   dest: myetc

Debugging
---------
  * `ssh -F /home/backuppuller/.ssh/config backupro@host test` 
  * `rsync -a --rsh="/usr/bin/ssh -F /home/backuppuller/.ssh/config" backupro@host:/path-to-dir .`

Inspired by
-------
  * [Backup remote Linux hosts without root access, using rsnapshot](http://dev.kprod.net/?q=linux-backup-rsnapshot-no-root)
  * [Restricting SSH Access to rsync](https://www.guyrutenberg.com/2014/01/14/restricting-ssh-access-to-rsync/)
  * [rsync as root with rrsync and sudo](https://www.v13.gr/blog/?p=216)
  * [Root, Sudo, and Rsnapshot](http://technokracy.net/2011/01/07/root_sudo_rsnapshot/)
  * [OpenSSH: Going flexible with forced commands](http://binblog.info/2008/10/20/openssh-going-flexible-with-forced-commands/)
  * [Ausführbare SSH-Kommandos per authorized keys einschränken](https://www.thomas-krenn.com/de/wiki/Ausf%C3%BChrbare_SSH-Kommandos_per_authorized_keys_einschr%C3%A4nken)
  * [Securing Rsync as Root](http://www.ullright.org/ullWiki/show/secure-rsync-via-ssh-as-root)
  * [Security of only allowing a few vetted commands using $SSH_ORIGINAL_COMMAND](https://security.stackexchange.com/questions/118688/)

License
-------

GPLv2

Author Information
------------------

Yannik Sembritzki
