#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright: (c) 2019-2020, Ivan Andreev
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'core'}


DOCUMENTATION = r'''
---
module: ferm_port
short_description: Manage ferm host rules
description:
  - ...
version_added: "2.8"
options:
  host:
    description:
      - IPv4 or IPv6 address or a DNS hostname.
    type: str
    required: true
  proto:
    description:
      - Limits DNS search in case of symbolic hostname;
      - Ignored in case of IPv4 or IPv6 address.
    type: str
    choices: [ ipv4, ipv6, any ]
    default: any
  domain:
    description:
      - C(internal) add host to the internal list;
      - C(blocked) blocks the host.
    type: str
    choices: [ internal, blocked ]
    default: external
  state:
    description:
      - Whether the rule should be added or removed.
    type: str
    choices: [ absent, present ]
    default: present
  reload:
    description:
      - Reload firewall rules in case of changes.
    default: true
  ferm_dir:
    description:
      - Ferm configuration directory.
    type: str
    default: /etc/ferm
seealso:
- module: ferm_host
- module: ferm_port
- module: ferm_rule
author:
    - Ivan Adnreev (@ivandeex)
'''

EXAMPLES = r'''
- name: Block the host
  ferm_host:
    host: badguy.com
    domain: blocked
'''

import os
import re
import tempfile

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils._text import to_bytes, to_native


def ferm_config(module, filename):

    ferm_dir = module.params['ferm_dir']
    dest = os.path.join(ferm_dir, filename)
    b_dest = to_bytes(dest, errors='surrogate_or_strict')
    if not os.path.exists(b_dest):
        module.fail_json(rc=257, msg='Config file %s does not exist!' % dest)

    b_path = os.path.realpath(b_dest)
    return to_native(b_path, errors='surrogate_or_strict')


def write_changes(module, path, b_lines, reload=True):

    tmpfd, tmpfile = tempfile.mkstemp()
    with os.fdopen(tmpfd, 'wb') as f:
        f.writelines(b_lines)

    module.atomic_move(tmpfile, path, unsafe_writes=False)

    if reload:
        cmd = ['systemctl', 'reload-or-restart', 'ferm.service']
        rc, stdout, stderr = module.run_command(cmd)
        if rc:
            module.fail_json(msg='Failed to reload ferm',
                             rc=rc, stdout=stdout, stderr=stderr)


def present(module, path, line, reload=True):

    with open(path, 'rb') as f:
        b_lines = f.readlines()

    diff = dict(before='', after='')
    if module._diff:
        diff['before'] = to_native(b''.join(b_lines))

    b_line = to_bytes(line, errors='surrogate_or_strict')
    b_linesep = to_bytes(os.linesep, errors='surrogate_or_strict')
    found = False
    changed = False
    msg = ''

    for lineno, b_cur_line in enumerate(b_lines):
        if b_line == b_cur_line.rstrip(b'\r\n'):
            found = True
            break

    if not found:
        # Add it to the end of the file
        # If the file is not empty then ensure there's a newline before the added line
        if b_lines and not b_lines[-1][-1:] in (b'\n', b'\r'):
            b_lines.append(b_linesep)
        b_lines.append(b_line + b_linesep)
        msg = 'line added'
        changed = True

    if module._diff:
        diff['after'] = to_native(b''.join(b_lines))

    if changed and not module.check_mode:
        write_changes(module, path, b_lines, reload)

    if module.check_mode and not os.path.exists(path):
        module.exit_json(changed=changed, msg=msg, diff=diff)

    module.exit_json(changed=changed, msg=msg, diff=diff)


def absent(module, path, line, reload=True):

    with open(path, 'rb') as f:
        b_lines = f.readlines()

    diff = dict(before='', after='')
    if module._diff:
        diff['before'] = to_native(b''.join(b_lines))

    b_line = to_bytes(line, errors='surrogate_or_strict')
    orig_len = len(b_lines)

    b_lines = [l for l in b_lines if b_line != l.rstrip(b'\r\n')]

    found = orig_len - len(b_lines)
    changed = found > 0
    msg = "%s line(s) removed" % found if changed else ''

    if changed and not module.check_mode:
        write_changes(module, path, b_lines, reload)

    if module._diff:
        diff['after'] = to_native(b''.join(b_lines))
    module.exit_json(changed=changed, found=found, msg=msg, diff=diff)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            host=dict(type='str', required=True),
            proto=dict(type='str', default='any', choices=['ipv4', 'ipv6', 'any']),
            domain=dict(type='str', default='internal', choices=['internal', 'blocked']),
            state=dict(type='str', default='present', choices=['present', 'absent']),
            reload=dict(type='bool', default=True),
            ferm_dir=dict(type='str', default='/etc/ferm'),
        ),
        supports_check_mode=True,
    )

    host = module.params['host']
    proto = module.params['proto']
    split = re.match('^(.+)/(ipv4|ipv6|any)$', host)
    if split:
        host, proto = split.group(1), split.group(2)

    if proto == 'any':
        line = host
    else:
        line = '%s/%s' % (host, proto)

    domain = module.params['domain']
    domain_to_extension = {
        'internal': 'int',
        'blocked': 'block',
    }
    if domain not in domain_to_extension:
        module.fail_json(rc=256, msg='Invalid domain argument')
    path = ferm_config(module, 'hosts.%s' % domain_to_extension[domain])

    reload = module.params['reload']
    if module.params['state'] == 'present':
        present(module, path, line, reload)
    else:
        absent(module, path, line, reload)


if __name__ == '__main__':
    main()
