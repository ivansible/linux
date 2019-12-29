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
  name:
    description:
      - Rule name.
    type: str
    required: true
  weight:
    description:
      - Relative rule order from 0 to 99.
    type: int
    default: 55
  hook:
    description:
      - Filter to hook to insert the rule.
    type: str
    choices: [ input, forward, before, after ]
    default: input
  rules:
    description:
      - Text of firewall rules, required if C(state) is C(present).
    type: str
    aliases: [ rule, snippet ]
  state:
    description:
      - Whether the rule should be added or removed.
    type: str
    choices: [ absent, present ]
    default: present
  backup:
    description:
      - Whether backup of existing rule should be saved.
    type: bool
    default: false
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
from ansible.module_utils._text import to_bytes


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            weight=dict(type='int', default=55),
            rules=dict(type='str', aliases=['rule', 'snippet']),
            hook=dict(type='str', default='input',
                      choices=['input', 'forward', 'before', 'after']),
            state=dict(type='str', default='present', choices=['present', 'absent']),
            backup=dict(type='bool', default=False),
            reload=dict(type='bool', default=True),
            ferm_dir=dict(type='str', default='/etc/ferm'),
        ),
        supports_check_mode=True,
    )

    name = module.params['name']
    weight = module.params['weight']
    if re.match(r'[\s\/]', name):
        module.fail_json(msg="Invalid name: '%s'" % name)
    if weight < 0 or weight > 99:
        module.fail_json(msg='Invalid weight: %d' % weight)

    hook_dir = os.path.join(module.params['ferm_dir'], module.params['hook'])
    if not os.path.isdir(hook_dir) or not os.access(hook_dir, os.W_OK):
        module.fail_json(msg='Directory is absent or not writable: ' + hook_dir)

    path = os.path.join(hook_dir, '%02d-%s.ferm' % (weight, name))
    b_path = to_bytes(path, errors='surrogate_or_strict')

    exists = os.path.exists(b_path)
    if exists and not os.path.isfile(b_path):
        module.fail_json(msg='Destination is not a regular file: ' + path)
    if exists and not os.access(b_path, os.W_OK):
        module.fail_json(msg='Destination is not writable: ' + path)

    changed = False
    msg = ''
    backup = module.params['backup']
    backup_file = None
    state = module.params['state']

    if state == 'absent' and exists:
        changed = True
        if not module.check_mode:
            if backup:
                backup_file = module.backup_local(path)
            os.remove(b_path)
            msg = 'Rule removed'

    if state == 'present':
        rules = module.params['rules']
        if rules is None:
            module.fail_json(msg='Please provide rules')
        b_rules = to_bytes(rules)

        if exists:
            with open(path, 'rb') as f:
                b_orig_rules = f.read()
            changed = b_rules != b_orig_rules
        else:
            changed = True

        if changed and not module.check_mode:
            tmpfd, tmpfile = tempfile.mkstemp()
            with os.fdopen(tmpfd, 'wb') as f:
                f.write(b_rules)

            if exists and backup:
                backup_file = module.backup_local(path)

            module.atomic_move(tmpfile, path, unsafe_writes=False)
            msg = 'Rule saved'

            module.set_mode_if_different(path, '0640', changed)
            module.set_owner_if_different(path, 'root', changed)
            module.set_group_if_different(path, 'root', changed)

    if changed and module.params['reload'] and not module.check_mode:
        cmd = ['systemctl', 'reload-or-restart', 'ferm.service']
        rc, stdout, stderr = module.run_command(cmd)
        if rc:
            module.fail_json(msg='Failed to reload ferm',
                             rc=rc, stdout=stdout, stderr=stderr)

    result = dict(changed=changed, msg=msg, path=path)
    if backup_file:
        result['backup_file'] = backup_file
    module.exit_json(**result)


if __name__ == '__main__':
    main()
