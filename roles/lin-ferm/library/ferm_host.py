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

import re

from ansible.module_utils.basic import AnsibleModule
from .ferm_port import ferm_config, present, absent


def main():
    module = AnsibleModule(
        argument_spec=dict(
            host=dict(type='str', required=True),
            proto=dict(type='str', default='any', choices=['ipv4', 'ipv6', 'any']),
            domain=dict(type='str', default='internal', choices=['internal', 'blocked']),
            state=dict(type='str', default='present', choices=['present', 'absent']),
            ferm_dir=dict(type='str', default='/etc/ferm'),
        ),
        supports_check_mode=True,
    )

    params = module.params

    host = params['host']
    proto = params['proto']
    split = re.match('^(.+)/(ipv4|ipv6|any)$', host)
    if split:
        host, proto = split.group(1), split.group(2)

    if proto == 'any':
        line = host
    else:
        line = '%s/%s' % (host, proto)

    domain = params['domain']
    domain_to_extension = {
        'internal': 'int',
        'blocked': 'block',
    }
    if domain not in domain_to_extension:
        module.fail_json(rc=256, msg='Invalid domain argument')
    path = ferm_config(module, 'hosts.%s' % domain_to_extension[domain])

    if params['state'] == 'present':
        present(module, path, line)
    else:
        absent(module, path, line)


if __name__ == '__main__':
    main()
