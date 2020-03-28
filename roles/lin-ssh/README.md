# ivansible.lin_ssh

[![Github Test Status](https://github.com/ivansible/lin-ssh/workflows/Molecule%20test/badge.svg?branch=master)](https://github.com/ivansible/lin-ssh/actions)
[![Travis Test Status](https://travis-ci.org/ivansible/lin-ssh.svg?branch=master)](https://travis-ci.org/ivansible/lin-ssh)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__ssh-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_ssh/)

This role will perform additional ssh configuration: harden permissions,
disable interactive ssh passwords etc.
Please note that since SSH port should be enabled in firewall *early*,
that task has been performed by the `lin-core` role rather than here.


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    lin_ssh_known_hosts: [github.com, ...]

If this list is not empty, add its items to the global list of known hosts
(normally `/etc/ssh/ssh_known_hosts`). Items are FQDN host names if standard SSH
port 22 is used, otherwise the item should be formatted as `host:port`.

    lin_ssh_settings: {...}
A dictionary with SSH daemon settings.

    lin_ssh_conn_limit: 1/sec
    lin_ssh_conn_burst: 9
Set limit on SSH connections per second (if `limit` is not an empty string).


### Optional Variables

    real_ssh_port: <optional>

This optional setting allows user to override auto-detected ssh port value,
which may be incorrect if ansible is run by the HashiCorp Packer or through
a reverse ssh tunnel or port forwarder.


### Imported Variables (ivansible.lin_base)

    lin_use_ssh: true
Unlocks this role (please lock if SSH can fail, eg. on github runners).


## Tags

- `lin_ssh_install` -- install openssh and activate ssh service
- `lin_ssh_firewall` -- open ssh ports in firewall
- `lin_ssh_settings` -- customize ssh settings (eg. harden the security)
- `lin_ssh_known_hosts` -- update global list of known hosts
- `lin_ssh_all` -- all actions


## Dependencies

- `ivansible.lin_base` -- for `ssh` restart handler and ssh enabling flag.


## Example Playbook

    - hosts: vagrant-boxes
      roles:
         - role: ivansible.lin_ssh


## License

MIT


## Author Information

Created in 2019-2020 by [IvanSible](https://github.com/ivansible)
