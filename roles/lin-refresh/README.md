# lin-refresh

Instantly updates time, packages and kernel on a linux machine.

## Requirements

None

## Role Variables

    lin_refresh_apt_sources: true

By default, if host belongs to the `vagrant` group, the role will replace
packet sources in `/etc/apt/sources.list` with links to presumably faster
`mirror.yandex.ru`.
To keep your apt sources intact, set this to `false`.

## Dependencies

None

## Example Playbook

    - hosts: vagrant-boxes
      strategy: free
      roles:
         - { role: ivansible.lin-refresh, lin_refresh_apt_sources: false }

## Usage

    ansible-playbook plays/lin-refresh.yml -l dock2,dock3

Make sure your hosts do not fall in the `vagrant` group.

## License

MIT

## Author Information

Created in 2018 by [IvanSible](https://github.com/ivansible)
