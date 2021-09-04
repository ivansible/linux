# ivansible.lin_restic

[![Github Test Status](https://github.com/ivansible/lin-restic/workflows/test/badge.svg?branch=master)](https://github.com/ivansible/lin-restic/actions)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__restic-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_restic/)

Install restic on linux and setup backup cron jobs.


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    lin_restic_version: latest
    lin_restic_repo_owner: restic
Version and fork of restic to install.

    lin_restic_authorized_keys: <lin_ssh_keys_files>
SSH keys to login with (restic user come password-less).

    lin_restic_rclone_remote: restic
Rclone remote for restic repository.

    lin_restic_rclone_config: ""
    lin_restic_rclone_token: ""
    lin_restic_rclone_reuse_token: false
If these are set, then respective remote will be configure by the role.
By default these are unset, and remote should be setup externally.

    lin_restic_reponame: <inventory_hosname>
    lin_restic_password: supersecret
Name and password of the restic repository.

    lin_restic_proxy: proto://host:port
Optional proxy, protocol is one of `http`,`https`,`socks`,`socks5`.

    lin_restic_cron_time_backup: 2:00
    lin_restic_cron_ordering: false
Fine-tune restic cron jobs (start daily at specified time).

    lin_restic_cron_time_prune: 5:00
    lin_restic_cron_day_prune: sun
Fine-tune when cron should start the prune job:
"sat" - on Saturday, "sun" - on Sunday, "mon-sun" - daily.
If these settings are empty, the prune job will be disabled.

    lin_restic_prune_pre_command: ~
    lin_restic_prune_post_command: ~
Optional shell commands to run before/after prune job.

    lin_restic_cron_verbose: 0
A positive value 1-3 will increase verbosity of timed restic runs.

    lin_restic_forget_keep_last: 2
    lin_restic_forget_keep_daily: 7
    lin_restic_forget_keep_weekly: 4
    lin_restic_forget_keep_monthly: 12
    lin_restic_forget_keep_yearly: 2
Fine-tune restic forget parameters (belongs with prune job).

    lin_restic_postgres_port: 5432
Default postgres server port for database backups.

    lin_restic_mount_dir: /mnt/restic
    lin_restic_job_dirs: []
Directories for rclone mount and command jobs.

    lin_restic_sudo_rules: [{user: postgres, command: /usr/bin/pg_dump}]...
Allow user restic to impersonate via `sudo` for backup jobs.
If `user` is root, you can use just a simple string with command instead of mapping.

    lin_restic_ssh_configs: []
Optional array of records. Each record must contain the following fields:
  - `section`  -- SSH config section (optional, default: SSH host alias)
  - `owner`    -- owner of ssh config file to add the record, eg. root (default: restic user)
  - `alias`    -- SSH host alias (default: host)
  - `host`     -- actual host name or ip address (REQUIRED)
  - `port`     -- ssh port (default: 22)
  - `user`     -- remote ssh user name (default: owner)
  - `keyfile`  -- ssh key file (optional, will be installed on host)

```
    lin_restic_jobs: []
```
Optional array of records. Each record must contain the following fields:
  - `name`     -- job name (REQUIRED)
  - `type`     -- keyword: `postgres` or `filesystem` or `command`
  - `database` -- database name or keyword `all`
  - `path`     -- filesystem path
  - `excludes` -- list of paths to exclude
  - `options`  -- list of options
  - `command`  -- freeform shell command
  - `disable`  -- optional flag to disable this job


## Tags

- `lin_restic_install` -- install restic binary
- `lin_restic_user` -- create dedicated restic user and job helpers
- `lin_restic_rclone` -- setup rclone remote
- `lin_restic_repo` -- setup restic repository
- `lin_restic_cron` -- activate restic cron jobs
- `lin_restic_mount` -- setup restic mount
- `lin_restic_all` -- all actions


## Dependencies

- `ivansible.lin_rclone`


## Example Playbook

    - hosts: masterhost
      roles:
        - role: ivansible.lin_restic
          lin_restic_password: secretpass
          lin_restic_jobs:
            - name: fs
              type: filesystem
              path: /
              excludes:
                - /swap
              options:
                - --exclude-caches
              tags: fs


## License

MIT

## Author Information

Created in 2019-2021 by [IvanSible](https://github.com/ivansible)
