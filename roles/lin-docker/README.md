# ivansible.lin_docker

Install
[docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository),
[docker-compose](https://docs.docker.com/compose/install/#install-compose),
[docker-machine](https://docs.docker.com/machine/install-machine/#install-machine-directly),
ansible docker bindings.


## Requirements

None


## Variables

    docker_swarm_role: none
The node role in the docker swarm:
- `worker` - worker-only node runs tasks
- `manager-worker` - manager node that runs tasks
- `manager-only` - manager node without tasks
- `manager-master` - first manager node in the swarm, runs tasks
- `none` - the node does not participate in swarm

```
docker_daily_gc: <depends on swarm>
```
Enables nightly docker garbage collector. Can be `true` or `false`. By default, enabled if the node participates in the swarm.

    docker_from_docker_io: true
    docker_focal_fix: true
If true (the default), install `docker engine` from the docker.io
repository and install `docker compose` from github.
If false, install docker engine and compose from native ubuntu repository.
As of May 2020, docker.io repository lacks a branch for `focal`,
and codename `eoan` is used as a temporary workaround.

    docker_compose_github_enable: depends on docker_from_docker_io
    docker_compose_release: latest
Install given `docker compose` release from github if the flag is `true`.
See new releases at https://github.com/docker/compose/releases

    docker_extras: false
    docker_machine_github_enable: false
    docker_machine_release: latest
Install given `docker machine` release from github if both flags are `true`.
See new releases at https://github.com/docker/machine/releases

    docker_upgrade: false
Allows to upgrade already installed docker packages.

    docker_permit_user: false
True allows to add target user in the docker group.

    docker_hub_username: ""
    docker_hub_password: ""
Use non-empty values to login target user into docker hub. Only user
in the docker group (`docker_permit_user` is true) will be authenticated.

    docker_files_repo: ""
    docker_files_dir: ~/devel/docker
If current host belongs to the `permitted` group and the URL of Git repository
with user _docker files_ is defined and not empty, the repository will be
checked out in the given local directory.

    docker_daemon_reset: true|false
    docker_daemon_user_settings: {}
    docker_daemon_user_labels: {}
    docker_daemon_base_labels: <derived from ansible node facts>
Custom docker daemon settings.
Labels should be provided as a map.
`none` and `empty` values are ignored. `-` values will be removed.

    docker_daemon_log_level: info|warn|error
    docker_daemon_use_criu: true|false|none
    docker_daemon_proxy: none|http://proxy_url
    docker_storage_driver: none|overlay2
Generic docker daemon settings.

    docker_tls_host: 127.0.0.1|0.0.0.0|none
    docker_listen_sockets: <unix socket, [http socket]>
Docker listen sockets.

    docker_bridge_addr4: 172.17.0.1/16
    docker_bridge_pool4: 172.16.0.0/12
    docker_enable_ipv6: true|false|none
    docker_bridge_subnet6: fdff:dead:beef::/64
Docker bridge (docker0) settings.

    docker_gwbridge_addr4: 172.18.0.1/16
    docker_gwbridge_force: false
Docker gwbridge settings.
Warning: if node is part of swarm, this step will fail with error:
`error while removing network: docker_gwbridge has active endpoints`
Fix it by setting `gwbridge_force` to `true`.

    docker_swarm_overlay_pool4: 10.0.0.0/8
    docker_swarm_ingress_subnet4: 10.255.0.0/16
    docker_swarm_ingress_encrypt: false
Swarm network settings.

    docker_tls_enable: false|true
    docker_tls_reset: false|true
    docker_tls_addr: 127.0.0.1|0.0.0.0|...
    docker_tls_ca_cname: ca.example.com
    docker_tls_server_cnames: [dockerd.example.com]
TLS settings.

    docker_reset: false
    docker_swarm_reset: false
    docker_swarm_destroy: false
These flags allow to reset all docker settings or detach node from swarm.


## Tags

- `lin_docker_engine`  -- install docker engine
- `lin_docker_daemon`  -- configure docker daemon
- `lin_docker_gwbridge`  -- configure gwbridge network
- `lin_docker_ansible` -- install ansible docker bindings
- `lin_docker_compose` -- install docker-compose
- `lin_docker_machine` -- install docker-machine
- `lin_docker_swarm` -- setup swarm
- `lin_docker_firewall` -- set firewall rules for docker
- `lin_docker_files` -- checkout docker files
- `lin_docker_bashrc` -- add user bash aliases
- `lin_docker_user` -- permissions for docker daemon
                       and login into docker hub
- `lin_docker_all` -- all tasks


## Dependencies

None


## Example Playbook

    - hosts: myhost
      roles:
        - role: ivansible.lin_docker


## License

MIT


## Author Information

Created in 2018-2020 by [IvanSible](https://github.com/ivansible)
