# ivansible.lin_wireguard

[![Github Test Status](https://github.com/ivansible/lin-wireguard/workflows/Molecule%20test/badge.svg?branch=master)](https://github.com/ivansible/lin-wireguard/actions)
[![Travis Test Status](https://travis-ci.org/ivansible/lin-wireguard.svg?branch=master)](https://travis-ci.org/ivansible/lin-wireguard)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__wireguard-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_wireguard/)

This role deploys Wireguard on linux.


## Requirements

None


## Variables

    lin_wg_forward: true
If this one is true, the role will enable packet forwarding
between Wireguard interfaces.

    lin_wg_host: "{{ ansible_default_ipv4.address }}"
Listening address for all wireguard subnets or `~` if not listening.

    lin_wg_nets: []
List of records, where each record describes one Wireguard subnet/device.
Names of interface devices for subnets are assigned sequentially: `wg0`, `wg1`...

    lin_wg_install_go: auto
Enables installing wireguard-go. By default enabled if kernel is older than `3.1`.

### Subnet Record

    name: net1
Name of subnet, informational (optional).

    port: 0
Listening port or `0` if not listening (default: not listening).

    addr: 10.1.1.1/24
IP address of local Wireguard node on this subnet with netmask bit length
or list of addresses/masks to assign to the VPN interface (REQUIRED).
Both IPv4 and IPv6 are supported and can be intermixed.

    key: ~
    pub: ~
    psk: ~
Private, public and preshared keys of local Wireguard node on this subnet.
Private key is required, but public key is purely informational.
Preshared key is optional.
You can use the following commands on Linux to generate new keys:
``wg genkey | tee key | wg pubkey; cat key
wg genpsk``

    mtu: 0
    keepalive: 0
These settings allow to force MTU on interface or enable persistent keepalive.

    metric: 0
Assign given metric to routes of peer on this subnet if this is non-zero.

    peers: []
List of records, where each record describes a remote Wireguard peer
on this subnet. The list can be nested, it will be flattened then.

### Peer Record

Peer records have the following fields:

    name
Peer name, informational, required.

    active
Optional boolean flag (default: true).

    key
    pub
    psk
Private, public and pre-shared keys of the peer.
Public key is required. Pre-shared key is optional.
Private key is purely informational (optional).

    ips
Allowed IPs, list of ip/mask pairs (ipv4 and ipv6 can be intermixed).
The list can be nested, it will be flattened then.

    host
IP address of peer endpoint, optional.

    port
Port of peer endpoint, optional, defaults to local wireguard port.


## Tags

- `lin_wg_install` -- install wireguard tools
- `lin_wg_go` -- install wireguard-go on old kernels
- `lin_wg_config` -- configure wireguard
- `lin_wg_firewall` -- open wireguard port and enable forwarding
- `lin_wg_service` -- enable wireguard service
- `lin_wg_all` -- all tasks


## Dependencies

`ivansible.lin_base`


## Example Playbook

    - hosts: vagrant-boxes
      roles:
         - role: ivansible.lin_wireguard
           lin_wg_port: 9876


## License

MIT


## Author Information

Created in 2020 by [IvanSible](https://github.com/ivansible)
