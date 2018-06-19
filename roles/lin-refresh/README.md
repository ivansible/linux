# ivansible.lin-refresh

Instantly updates time, packages and kernel on a linux machine.


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    linref_apt_sources: true

By default, if host belongs to the `vagrant` group, the role will replace
packet sources in `/etc/apt/sources.list` with links to presumably faster
`mirror.yandex.ru`.
To keep your apt sources intact, set this to `false`.

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

- `linref_mirrors` - Switch to yandex apt mirrors
- `linref_timesync` - Synchronize system time
- `linref_upgrade` - Perform dist-upgrade
- `linref_reboot` - Check for reboot marker, reboot and wait to come back


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

    ansible-playbook plays/lin-refresh.yml -l dock2,dock3

`Warning`: make sure your production hosts do not fall in the `vagrant` group.


## License

MIT

## Author Information

Created in 2018 by [IvanSible](https://github.com/ivansible)
