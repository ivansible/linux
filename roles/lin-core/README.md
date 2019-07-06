# ivansible.lin_system

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

    linbase_secure: true

Enable firewall and disable empty ssh passwords.

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


## Tags

- `linbase_mirrors` -- switch to fast apt mirrors
- `linbase_packages` -- install common software
- `linbase_telemetry` -- disable telemetry on bionic
- `linbase_timesync` -- synchronize system time
- `linbase_sysctl` -- kernel parameter adjustments
- `linbase_ssh` -- ssh adjustments
- `linbase_firewall` -- firewall adjustments
- `linbase_settings` -- system settings adjustments


## Dependencies

- `ivansible.lin_base` -- for `ssh` restart handler


## Example Playbook

    - hosts: vagrant-boxes
      strategy: free
      roles:
         - role: ivansible.lin_system
           linbase_apt_fast_mirrors: true
           linbase_secure: false


## License

MIT

## Author Information

Created in 2018 by [IvanSible](https://github.com/ivansible)
