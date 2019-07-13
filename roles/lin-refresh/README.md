# ivansible.lin_refresh

Instantly updates time, packages and kernel on a linux machine.


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    allow_reboot: true

If `true`, the script will reboot target host after critical upgrade.
Otherwise, the script will print a warning message and skip rebooting.


## Tags

- `linref_timesync` -- synchronize system time
- `linref_upgrade` -- perform dist-upgrade
- `linref_reboot` -- reboot and wait to come back if reboot flag is set


## Dependencies

None


## Example Playbook

    - hosts: vagrant-boxes
      strategy: free
      roles:
         - role: ivansible.lin_refresh
           become: yes
           linref_apt_sources: false


## Usage

    ansible-playbook plays/lin-refresh.yml -l vag2,vag3

`Warning`: make sure your production hosts do not fall in the `vagrant` group.


## License

MIT

## Author Information

Created in 2018 by [IvanSible](https://github.com/ivansible)
