# ivansible.lin_wireguard

[![Github Test Status](https://github.com/ivansible/lin-wireguard/workflows/Molecule%20test/badge.svg?branch=master)](https://github.com/ivansible/lin-wireguard/actions)
[![Travis Test Status](https://travis-ci.org/ivansible/lin-wireguard.svg?branch=master)](https://travis-ci.org/ivansible/lin-wireguard)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__wireguard-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_wireguard/)

This role deploys Wireguard on linux.


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    lin_wg_iface: wg0
Network interface for Wireguard.

    lin_wg_addr: 10.1.1.1/24
IP address with netmask bit length or list of addresses/masks to assign to
VPN interface. Both IPv4 and IPv6 are supported and can be intermixed.

    lin_wg_host: "{{ ansible_default_ipv4.address }}"
Listening address or `~` if not listening.
    lin_wg_port: 0
Listening port or zero if not listening.

    lin_wg_key: ~
    lin_wg_pub: ~
    lin_wg_psk: ~
Private, public and preshared keys of local Wireguard node.
Private key is required, but public key is purely informational.
Preshared key is optional.
You can use the following commands on Linux to generate new keys:
``wg genkey | tee key | wg pubkey; cat key
wg genpsk``

    lin_wg_mtu: 0
    lin_wg_keepalive: 0
These settings allow to force MTU on interface or enable persistent keepalive.

    lin_wg_metric: 0
Assign given metric to new routes if this is non-zero.

    lin_wg_forward: true
If this one is true, the role will allow packet forwarding
between Wireguard interfaces.

    lin_wg_peers: []
This is an array of records, where each record describes remote Wireguard peer
and has the following fields:
  - `name` -- peer name, informational, required
  - `active` -- optional boolean flag, defaults to true
  - `key` -- private key, informational, not required
  - `pub` -- public key, required
  - `psk` -- preshared key, optional
  - `ips` -- allowed IPs, list of ip/mask pairs (ipv4 and ipv6 can be intermixed)
  - `host` -- IP address of endpoint, optional
  - `port` -- port of endpoint, optional, defaults to lin_wg_port


## Tags

- `lin_wg_install` -- install wireguard tools
- `lin_wg_go` -- install wireguard-go on old kernels
- `lin_wg_conf` -- configure wireguard
- `lin_wg_firewall` -- open wireguard port and enable forwarding
- `lin_wg_service` -- enable wireguard service
- `lin_wg_all` -- all tasks


## Dependencies

`ivansible.lin_base`


## Example Playbook

    - hosts: vagrant-boxes
      roles:
         - role: lin_wireguard
           lin_wg_port: 9876


## License

MIT


## Author Information

Created in 2020 by [IvanSible](https://github.com/ivansible)
