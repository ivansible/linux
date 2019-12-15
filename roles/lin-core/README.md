# ivansible.lin_system

[![Github Test Status](https://github.com/ivansible/lin-system/workflows/Molecule%20test/badge.svg?branch=master)](https://github.com/ivansible/lin-system/actions)
[![Travis Test Status](https://travis-ci.org/ivansible/lin-system.svg?branch=master)](https://travis-ci.org/ivansible/lin-system)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__system-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_system/)

Perform basic configuration of a linux box:
 - switch to fast apt mirrors;
 - enable ntp and step-sync system time;
 - install common software;
 - adjust system locale and time zone;
 - tune kernel parameters (sysctl);
 - disable empty passwords and harden ssh permissions;
 - enable firewall;
 - disable telemetry on bionic (see https://askubuntu.com/a/1030168);


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    real_ssh_port: <optional>
This optional setting lets the user override an auto-detected ssh port value,
which may be incorrect if ansible is run by the hashicorop packer or through
a reverse ssh or port forwarder. An incorrect value would result in the real
ssh port being firewalled by the role.

    linbase_apt_fast_mirrors: false

If this setting is `true` (usually in the `vagrant` host group),
the role will replace package sources in `/etc/apt/sources.list`
with links to presumably faster `mirror.yandex.ru`.

    linbase_system_locale: ''

Preferred system locale, e.g. `en_US.UTF-8`

    linbase_timezone: ''

Preferred time zone, e.g. `Europe/Moscow`.

    linbase_sysctl:
      name: value
      ...

Desired sysctl settings, will be recorded in `/etc/sysctl.d/77-system.conf`

    linbase_swap_enable: false
Enables or disables confiration of swap file.

    linbase_swap_mb: 0
Swap file size in megabytes

    linbase_swap_file: /swap
Path to the swap file.

    linbase_golang_version: 1.13

Golang toolchain version to install (skip install if empty).

### Imported Variables (ivansible.lin_base)

    lin_use_firewall: true
    lin_use_ssh: true

Improve security -- enable uncomplicated firewall, disable empty ssh passwords etc.
Note: firewall can fail in docker containers, ssh can fail on github runners.


## Tags

- `linbase_mirrors` -- switch to fast apt mirrors
- `linbase_packages` -- install common software
- `linbase_telemetry` -- disable telemetry on bionic
- `linbase_goloang` -- install golang toolchain
- `linbase_timesync` -- synchronize system time
- `linbase_sysctl` -- adjust kernel parameters
- `linbase_swap` -- setup swap space
- `linbase_ssh` -- adjust global ssh settings
- `linbase_firewall` -- adjust ubuntu firewall
- `linbase_settings` -- adjust system settings - locale, timezone etc
- `linbase_motd` -- disable some motd banners
- `linbase_all` -- all of above


## Dependencies

- `ivansible.lin_base` -- for `ssh` restart handler


## Example Playbook

    - hosts: docker-box
      strategy: free
      roles:
         - role: ivansible.lin_system
           linbase_apt_fast_mirrors: true
           lin_use_firewall: false # firewall fails in docker


## License

MIT

## Author Information

Created in 2018-2020 by [IvanSible](https://github.com/ivansible)
