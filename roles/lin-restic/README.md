# ivansible.lin_restic

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

    lin_restic_cron_time_backup: 2:00
    lin_restic_cron_ordering: false
Fine-tune restic cron jobs (start daily at specified time).

    lin_restic_cron_time_prune: 5:00
    lin_restic_cron_day_prune: sun
Fine-tune when cron should start the prune job:
"sat" - on Saturday, "sun" - on Sunday, "mon-sun" - daily.

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


## Tags

- `lin_restic_install` -- install restic binary
- `lin_restic_user` -- create dedicated restic user
- `lin_restic_rclone` -- setup rclone remote
- `lin_restic_repo` -- setup restic repository
- `lin_restic_cron` -- activate restic cron jobs
- `lin_restic_all` -- all actions


## Dependencies

- ivansible.lin_rclone


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

Created in 2019-2020 by [IvanSible](https://github.com/ivansible)
