# ivansible.lin_core

[![Github Test Status](https://github.com/ivansible/lin-core/workflows/Molecule%20test/badge.svg?branch=master)](https://github.com/ivansible/lin-core/actions)
[![Travis Test Status](https://travis-ci.org/ivansible/lin-core.svg?branch=master)](https://travis-ci.org/ivansible/lin-core)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__core-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_core/)

Perform basic configuration of a linux box:
 - switch to fast apt mirrors;
 - enable ntp and step-sync system time;
 - install common software;
 - adjust system locale and time zone;
 - adjust cron timers;
 - tune kernel parameters (sysctl);
 - enable firewall, including ssh port fix (if allowed);
 - disable telemetry on bionic (see https://askubuntu.com/a/1030168);


## Requirements

None


## Variables

Main variables are listed below:

    lin_core_resync: false
Allows step-syncing hosts time.
This step may take long, disabled by default.

    lin_core_apt_fast_mirrors: false
If this setting is `true` (usually in the `vagrant` host group),
the role will replace package sources in `/etc/apt/sources.list`
with links to local repository mirrors.

    lin_core_apt_disable_32bit: false
This flag disable 32-bit apt repositories.

    lin_core_system_locale: ''
Preferred system locale, e.g. `en_US.UTF-8`

    lin_core_timezone: ''
Preferred time zone, e.g. `Europe/Berlin`.

    lin_cron_adjust: false
    lin_cron_timers:
      hourly: hourly
      daily: daily
      weekly: weekly
      monthly: monthly

This flag and map allows to adjust calendar of systemd cron timers,
e.g. make ubuntu 16.04 cron timers compatible with ubuntu 18.04.

    lin_core_sysctl:
      name: value
      ...

Desired sysctl settings, will be recorded in `/etc/sysctl.d/77-system.conf`

    lin_core_swap_enable: false
Enables or disables confiration of swap file.

    lin_core_swap_mb: 0
Swap file size in megabytes

    lin_core_swap_file: /swap
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

    lin_use_rsyslog: true
Enables rsyslog.


## Tags

- `lin_core_apt` -- adjust apt settings
- `lin_core_packages` -- install common software
- `lin_core_telemetry` -- disable telemetry on bionic
- `lin_core_timesync` -- synchronize system time
- `lin_core_resync` -- step-syncing system time
- `lin_core_cron` -- adjust systemd cron timers
- `lin_core_sysctl` -- adjust kernel parameters
- `lin_core_swap` -- setup swap space
- `lin_core_ssh` -- configure ssh port
- `lin_core_firewall` -- adjust ubuntu firewall
- `lin_core_settings` -- adjust system settings - locale, timezone etc
- `lin_core_utils` -- install helper scripts
- `lin_core_all` -- all of above


## Dependencies

- `ivansible.lin_base` -- for ferm modules, `ssh` restart handler, `lin_firewall` etc
- `ivansible.lin_ferm` -- to install ferm


## Example Playbook

    - hosts: docker-box
      strategy: free
      roles:
         - role: ivansible.lin_core
           lin_core_apt_fast_mirrors: true
           lin_firewall: none  # firewall fails in docker


## License

MIT

## Author Information

Created in 2018-2020 by [IvanSible](https://github.com/ivansible)
