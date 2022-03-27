import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')

# port 0 disables ssh tests
SSH_PORT = int(os.environ.get('IVATEST_SSH_PORT') or 0)


def test_hosts_file(host):
    f = host.file('/etc/hosts')
    assert f.exists
    assert f.user == 'root'
    assert f.group == 'root'


def test_google_reachable(host):
    google = host.addr("google.com")
    assert google.is_resolvable
    # assert google.is_reachable  # skip because ping fails on github runners
    assert google.port(443).is_reachable


def test_ssh_service(host):
    if not SSH_PORT:
        return
    ssh = host.service("ssh")
    assert ssh.is_running
    assert ssh.is_enabled


def test_ssh_port(host):
    if not SSH_PORT:
        return
    sock = host.socket("tcp://0.0.0.0:%s" % SSH_PORT)
    assert sock.is_listening
