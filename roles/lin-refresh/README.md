# ivansible.lin-refresh

Instantly updates time, packages and kernel on a linux machine.

## Requirements

None

## Variables

Available variables are listed below, along with default values.

    lin_refresh_apt_sources: true

By default, if host belongs to the `vagrant` group, the role will replace
packet sources in `/etc/apt/sources.list` with links to presumably faster
`mirror.yandex.ru`.
To keep your apt sources intact, set this to `false`.

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
           lin_refresh_apt_sources: false

## Usage

    ansible-playbook plays/lin-refresh.yml -l dock2,dock3

Make sure your hosts do not fall in the `vagrant` group.

## License

MIT

## Author Information

Created in 2018 by [IvanSible](https://github.com/ivansible)
