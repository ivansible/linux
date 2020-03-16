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
 - enable firewall, including ssh port fix (if allowed);
 - disable telemetry on bionic (see https://askubuntu.com/a/1030168);


## Requirements

None


## Variables

Main variables are listed below:

    linsys_resync: false
Allows step-syncing hosts time.
This step may take long, disabled by default.

    linsys_apt_fast_mirrors: false

If this setting is `true` (usually in the `vagrant` host group),
the role will replace package sources in `/etc/apt/sources.list`
with links to presumably faster `mirror.yandex.ru`.

    linsys_system_locale: ''

Preferred system locale, e.g. `en_US.UTF-8`

    linsys_timezone: ''

Preferred time zone, e.g. `Europe/Moscow`.

    linsys_sysctl:
      name: value
      ...

Desired sysctl settings, will be recorded in `/etc/sysctl.d/77-system.conf`

    linsys_swap_enable: false
Enables or disables confiration of swap file.

    linsys_swap_mb: 0
Swap file size in megabytes

    linsys_swap_file: /swap
Path to the swap file.


### Optional Variables

    real_ssh_port: <optional>

This optional setting allows user to override auto-detected ssh port,
which may be incorrect if ansible is run by the HashiCorp Packer
or through a reverse ssh tunnel or port forwarder.
Incorrect value may result in the real ssh port being firewalled by the role.


### Imported Variables (ivansible.lin_base)

    lin_firewall: ferm
Linux firewall to use, one of: `ufw`, `ferm`, `none` (firewall can fail in docker).

    lin_use_ssh: true
Enables SSH daemon (can fail on github runners).

    lin_use_syslog: true
Enables rsyslog.


## Tags

- `linsys_mirrors` -- switch to fast apt mirrors
- `linsys_packages` -- install common software
- `linsys_telemetry` -- disable telemetry on bionic
- `linsys_timesync` -- synchronize system time
- `linsys_resync` -- step-syncing system time
- `linsys_sysctl` -- adjust kernel parameters
- `linsys_swap` -- setup swap space
- `linsys_ssh` -- configure ssh port
- `linsys_firewall` -- adjust ubuntu firewall
- `linsys_settings` -- adjust system settings - locale, timezone etc
- `linsys_utils` -- install helper scripts
- `linsys_all` -- all of above


## Dependencies

- `ivansible.lin_base` -- for ferm modules, `ssh` restart handler, `lin_firewall` etc
- `ivansible.lin_ferm` -- to install ferm


## Example Playbook

    - hosts: docker-box
      strategy: free
      roles:
         - role: ivansible.lin_system
           linsys_apt_fast_mirrors: true
           lin_firewall: none  # firewall fails in docker


## License

MIT

## Author Information

Created in 2018-2020 by [IvanSible](https://github.com/ivansible)
