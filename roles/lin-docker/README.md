# Role ivansible.lin-docker

Install
[docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository),
[docker-compose](https://docs.docker.com/compose/install/#install-compose),
[docker-machine](https://docs.docker.com/machine/install-machine/#install-machine-directly),
ansible docker bindings.


## Requirements

None


## Variables

Available variables are listed below, along with default values.


    docker_machine_release: latest

Docker-machine release to install. See new releases at
https://github.com/docker/machine/releases

    docker_compose_release: latest

Docker-compose release to install. See new releases at
https://github.com/docker/compose/releases

    docker_allow_reinstall: no

Allows to refresh already downloaded docker redistributables.


## Tags

- `lin_docker_core` -- install docker core
- `lin_docker_ansible` -- install ansible docker bindings
- `lin_docker_compose` -- install docker-compose
- `lin_docker_machine` -- install docker-machine
- `lin_docker_user` -- give target user permissions for docker


## Dependencies

None


## Example Playbook

    - hosts: vag2
      roles:
        - role: ivansible.lin-docker


## License

MIT


## Author Information

Created in 2018 by [IvanSible](https://github.com/ivansible)
