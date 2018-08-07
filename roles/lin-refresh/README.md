# ivansible.lin-refresh

Instantly updates time, packages and kernel on a linux machine.


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    linref_reboot_allow: true

If `true`, the script will reboot target host after critical updagrade.
Otherwise, the script will print a warning message and skip rebooting.

    linref_reboot_pause: nowait

Time to wait for user keypress before reboot if this reboot is required
due to critical upgrades.
- `'nowait'` - do not wait
- `'pause'` - wait forever until user hits `Enter` or cancels with `Ctrl-C`
- `1`..`1000` - integer number of seconds to wait

The default value of `nowait` is compatible with the `free` play strategy
and allows to upgrade many targets in parallel.


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
         - role: ivansible.lin-refresh
           become: yes
           linref_apt_sources: false


## Usage

    ansible-playbook plays/lin-refresh.yml -l vag2,vag3

`Warning`: make sure your production hosts do not fall in the `vagrant` group.


## License

MIT

## Author Information

Created in 2018 by [IvanSible](https://github.com/ivansible)
