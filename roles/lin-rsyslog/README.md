# ivansible.lin_syslog

[![Github Test Status](https://github.com/ivansible/lin-syslog/workflows/Molecule%20test/badge.svg?branch=master)](https://github.com/ivansible/lin-syslog/actions)
[![Travis Test Status](https://travis-ci.org/ivansible/lin-syslog.svg?branch=master)](https://travis-ci.org/ivansible/lin-syslog)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__syslog-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_syslog/)

This role configures rsyslog service so that some chatty subsystems
are logged in separate log files, and configures rotation of these logs:
- mail services
- firewall (ufw)
- cron
- drupal
- keenetic
- php session cleaner


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    lin_syslog_keenetic_ip: ""
IP address of keenetic logger, logs keenetic to dedicated log
(empty value keeps it in common log).

    lin_syslog_separate_ufw: false
Logs ufw (firewall) messages to dedicated log.

    lin_syslog_separate_drupal: false
Logs drupal to dedicated log.

    lin_syslog_separate_cron: false
Logs cron to dedicated log.

    lin_syslog_thin_php_cleaner: false
Thin out messages of the PHP session cleaner.

    lin_syslog_force_rules: false
Force overriding previous syslog rules.


## Tags

- `lin_syslog_packages` -- install rsyslog and logrotate
- `lin_syslog_docker` -- disable kernel logging in docker
- `lin_syslog_mail` -- configure mail logging
- `lin_syslog_ufw` -- configure ufw logging
- `lin_syslog_drupal` -- rotate drupal log
- `lin_syslog_keenetic` -- rotate keenetic log
- `lin_syslog_cron` -- rotate cron log
- `lin_syslog_php` -- thin out php cleaner messages
- `lin_syslog_all` -- all actions


## Dependencies

This role imports global flag `lin_use_syslog` from role `lin_base`
and activates only of it's `true`.


## Example Playbook

    - hosts: host1
      roles:
         - role: lin_syslog


## License

MIT


## Author Information

Created in 2019-2020 by [IvanSible](https://github.com/ivansible)
