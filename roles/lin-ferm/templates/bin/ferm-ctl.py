#!/usr/bin/python3
# -*- coding: utf-8 -*-
# Copyright: (c) 2020, Ivan Andreev
# GNU General Public License v3.0+

import os
import sys
import re
import argparse
import codecs
import subprocess

FERM_DIR = '/etc/ferm'

ZONES = {
    'internal': 'int',
    'int': 'int',
    'external': 'ext',
    'ext': 'ext',
    'blocked': 'block',
    'block': 'block',
}

LIST_CHOICES = [
    'hosts.int',
    'hosts.block',
    'ports.ext',
    'ports.int',
    'ports.block',
]

PROTO_CHOICES = [
    'any',
    'tcp',
    'udp',
    'ipv4',
    'ipv6',
]

ENCODING = 'utf-8'
ENCODING_ERRORS = 'strict'
try:
    if codecs.lookup_error('surrogateescape'):
        ENCODING_ERRORS = 'surrogateescape'
except LookupError:
    pass

VALID_HOST = r'^(([0-9]{1,3}[.]){3}[0-9]{1,3}' \
             r'|[0-9a-fA-F:]*:[0-9a-fA-F:]*' \
             r'|[0-9a-zA-Z_.-]+)$'
VALID_PORT = r'^[0-9]{1,5}([:-][0-9]{1,5})?$'

T_SEP = '\r\n'
B_SEP = b'\r\n'
B_EOL = os.linesep.encode()


def fail(msg):
    if msg:
        print(msg, file=sys.stderr)
    sys.exit(1)


def to_bytes(obj):
    if isinstance(obj, bytes):
        return obj
    elif isinstance(obj, str):
        return obj.encode(ENCODING, ENCODING_ERRORS)
    else:
        raise TypeError('obj must be a string type')


def to_text(obj):
    if isinstance(obj, str):
        return obj
    elif isinstance(obj, bytes):
        return obj.decode(ENCODING, ENCODING_ERRORS)
    else:
        raise TypeError('obj must be a string type')


def run_command(args):
    if not isinstance(args, list):
        args = args.split()
    try:
        cmd = subprocess.Popen(
            [to_bytes(x) for x in args],
            close_fds=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = cmd.communicate()
        return cmd.returncode, to_text(stdout), to_text(stderr)
    except (OSError, IOError) as e:
        fail("CMD:'%s' Exception:'%s'" % (' '.join(args), e))


def ferm_config(filename):
    dest = os.path.join(FERM_DIR, filename)
    if not os.path.exists(to_bytes(dest)):
        fail("Config file '%s' does not exist!" % dest)
    return to_text(os.path.realpath(to_bytes(dest)))


def write_changes(path, b_lines, args):
    if args.dry_run:
        return
    if args.backup:
        run_command(['cp', '-a', path, path + '~'])
    with open(path, 'wb') as f:
        f.writelines(b_lines)


def reload_ferm(args):
    if args.dry_run:
        return
    if os.path.isdir('/proc/vz'):
        cmd = 'systemctl reload-or-restart ferm'
    else:
        cmd = 'ferm-ipset'
    ret, _, err = run_command(cmd)
    if ret:
        fail('Failed to reload ferm: %s' % err)


def handle_hosts(items, state, zone, exclude, counts, args):
    path = ferm_config('hosts.%s' % ZONES[zone])
    with open(path, 'rb') as f:
        b_lines = f.readlines()

    changed = False

    for host in items:
        host = str(host).strip() if host else ''
        proto = args.proto
        prefixlen = None
        comment = args.comment or ''
        add = state == 'present'

        if host.startswith('-'):
            host = host[1:].strip()
            add = False
        if not host:
            continue

        if exclude:
            if add:
                add = False
            else:
                continue

        split = re.match(r'^([^#;~]*)[#;~](.*)$', host)
        if split:
            host, comment = split.group(1).strip(), split.group(2).strip()
        comment = comment.rstrip(T_SEP).replace('~', ' ')
        b_comment = to_bytes(comment)

        split = re.match(r'^(.+)/(ipv4|ipv6|any)$', host)
        if split:
            host, proto = split.group(1), split.group(2)
        split = re.match(r'^(.+)/([0-9]+)$', host)
        if split:
            host, prefixlen = split.group(1), int(split.group(2))

        if not re.match(VALID_HOST, host):
            fail("Invalid host '%s'" % host)
        if prefixlen is not None and (prefixlen < 0 or prefixlen > 128):
            fail("Invalid prefixlen %d" % prefixlen)

        line = host
        if prefixlen is not None:
            line = '%s/%d' % (line, prefixlen)
        if proto != 'any':
            line = '%s/%s' % (line, proto)

        b_line = to_bytes(line)
        b_new_line = b_line
        if b_comment:
            b_new_line += b' # ' + b_comment

        regexp = r'^\s*(%s)\s*(?:#+\s*(.*)\s*)?$' % line
        b_regex = re.compile(to_bytes(regexp))

        solo_comment = args.solo_comment and b_comment
        if solo_comment:
            comm_regexp = r'^\s*(.*)\s*#+\s*(%s)\s*$' % comment
            b_comm_re = re.compile(to_bytes(comm_regexp))

        if add:
            b_prev_lines = b_lines
            b_lines = []
            found = False
            comm_found = False

            for b_cur_line in b_prev_lines:
                match = b_regex.match(b_cur_line.rstrip(B_SEP))
                if match and (found or comm_found):
                    # remove duplicates
                    counts['deduped'] += 1
                    changed = True
                elif match and not found:
                    found = True
                    if not b_comment or b_comment == match.group(2):
                        b_lines.append(b_cur_line)
                    else:
                        b_lines.append(b_new_line + B_EOL)
                        counts['updated'] += 1
                        changed = True
                elif solo_comment:
                    comm_match = b_comm_re.match(b_cur_line.rstrip(B_SEP))
                    if comm_match and comm_found:
                        counts['deduped'] += 1
                        changed = True
                    elif comm_match and not comm_found:
                        comm_found = True
                        if b_line == comm_match.group(1):
                            b_lines.append(b_cur_line)
                        else:
                            b_lines.append(b_new_line + B_EOL)
                            counts['updated'] += 1
                            changed = True
                    else:
                        b_lines.append(b_cur_line)
                else:
                    b_lines.append(b_cur_line)

            if not found and not comm_found:
                # add to the end of file ensuring there's a newline before it
                if b_lines and not b_lines[-1][-1:] in B_SEP:
                    b_lines.append(B_EOL)
                b_lines.append(b_new_line + B_EOL)
                counts['added'] += 1
                changed = True
        else:
            orig_len = len(b_lines)
            b_lines = [l for l in b_lines
                       if not b_regex.match(l.rstrip(B_SEP))]
            removed = orig_len - len(b_lines)
            counts['removed'] += removed
            if removed > 0:
                changed = True

    if changed:
        write_changes(path, b_lines, args)

    return changed


def handle_ports(items, state, zone, exclude, counts, args):
    path = ferm_config('ports.%s' % ZONES[zone])
    with open(path, 'rb') as f:
        b_lines = f.readlines()

    changed = False

    for port in items:
        port = str(port).strip() if port else ''
        proto = args.proto
        comment = args.comment or ''
        add = state == 'present'

        if port.startswith('-'):
            port = port[1:].strip()
            add = False
        if not port:
            continue

        if exclude:
            if add:
                add = False
            else:
                continue

        split = re.match(r'^([^#;~]*)[#;~](.*)$', port)
        if split:
            port, comment = split.group(1).strip(), split.group(2).strip()
        comment = comment.rstrip(T_SEP).replace('~', ' ')
        b_comment = to_bytes(comment)

        split = re.match(r'^([^/]+)/(tcp|udp|any)$', port)
        if split:
            port, proto = split.group(1), split.group(2)

        if not re.match(VALID_PORT, port):
            fail("Invalid port '%s'" % port)

        port = port.replace('-', ':')
        line = port if proto == 'any' else '%s/%s' % (port, proto)
        b_line = to_bytes(line)

        b_new_line = b_line
        if b_comment:
            b_new_line += b' # ' + b_comment

        regexp = r'^\s*(%s)\s*(?:#+\s*(.*)\s*)?$' % line
        b_regex = re.compile(to_bytes(regexp))

        solo_comment = args.solo_comment and b_comment
        if solo_comment:
            comm_regexp = r'^\s*(.*)\s*#+\s*(%s)\s*$' % comment
            b_comm_re = re.compile(to_bytes(comm_regexp))

        if add:
            b_prev_lines = b_lines
            b_lines = []
            found = False
            comm_found = False

            for b_cur_line in b_prev_lines:
                match = b_regex.match(b_cur_line.rstrip(B_SEP))
                if match and (found or comm_found):
                    # remove duplicates
                    counts['deduped'] += 1
                    changed = True
                elif match and not found:
                    found = True
                    if not b_comment or b_comment == match.group(2):
                        b_lines.append(b_cur_line)
                    else:
                        b_lines.append(b_new_line + B_EOL)
                        counts['updated'] += 1
                        changed = True
                elif solo_comment:
                    comm_match = b_comm_re.match(b_cur_line.rstrip(B_SEP))
                    if comm_match and comm_found:
                        counts['deduped'] += 1
                        changed = True
                    elif comm_match and not comm_found:
                        comm_found = True
                        if b_line == comm_match.group(1):
                            b_lines.append(b_cur_line)
                        else:
                            b_lines.append(b_new_line + B_EOL)
                            counts['updated'] += 1
                            changed = True
                    else:
                        b_lines.append(b_cur_line)
                else:
                    b_lines.append(b_cur_line)

            if not found and not comm_found:
                # add to the end of file ensuring there's a newline before it
                if b_lines and not b_lines[-1][-1:] in B_SEP:
                    b_lines.append(B_EOL)
                b_lines.append(b_new_line + B_EOL)
                counts['added'] += 1
                changed = True
        else:
            orig_len = len(b_lines)
            b_lines = [l for l in b_lines
                       if not b_regex.match(l.rstrip(B_SEP))]
            removed = orig_len - len(b_lines)
            counts['removed'] += removed
            if removed > 0:
                changed = True

    if changed:
        write_changes(path, b_lines, args)

    return changed


def exit(changed, msg, verbose):
    if changed and verbose >= 1:
        print('changed')
    if msg and verbose >= 2:
        print(msg)
    sys.exit(0)


def main():
    def subcommand(cmds, names, state, help):
        cmd = cmds.add_parser(names[0], aliases=names[1:], help=help)
        cmd.add_argument('list', choices=LIST_CHOICES,
                         help='list to print or modify')
        cmd.set_defaults(state=state)
        if state != 'cat':
            cmd.add_argument('item', nargs='+',
                             help='list of ports or IP addresses')
        return cmd

    parser = argparse.ArgumentParser(description='ferm control utility')
    parser.add_argument('--verbose', '-v', action='count', default=0,
                        help='increase verbosity')
    parser.add_argument('--dry-run', '-n', action='store_true',
                        help='test whether changed would be done')
    parser.add_argument('--backup', '-b', action='store_true',
                        help='create backup of the old list content')
    parser.add_argument('--comment', '-c')
    parser.add_argument('--proto', '-p', choices=PROTO_CHOICES, default='any',
                        help='protocol: IPv4/v6 for hosts, tcp/udp for ports')
    parser.add_argument('--solo-zone', '-Z', action='store_true',
                        help='keep item(s) added in one list only')
    parser.add_argument('--solo-comment', '-C', action='store_true',
                        help='remove other items with the same comment')

    cmds = parser.add_subparsers(dest='command', metavar='<command>')
    subcommand(cmds, ['cat', 'ls'], 'cat', 'print given list')
    subcommand(cmds, ['add'], 'present', 'add ports/hosts to the list')
    subcommand(cmds, ['del', 'rm'], 'absent', 'remove items from list')

    args = parser.parse_args()
    if not args.command:
        parser.print_usage()
        fail(None)

    subject = args.list.split('.')[0]
    zone = args.list.split('.')[1]
    if subject == 'hosts':
        handle = handle_hosts
    elif subject == 'ports':
        handle = handle_ports
    else:
        zone = None

    zone = ZONES.get(zone, None)
    if not zone:
        fail("Invalid list '%s'" % args.list)

    path = ferm_config('%s.%s' % (subject, zone))
    b_path = to_bytes(path)
    if not (os.access(b_path, os.R_OK) and os.access(b_path, os.W_OK)):
        fail("%s: access denied" % path)

    state = args.state
    if state == 'cat':
        rc, stdout, _ = run_command(['cat', path])
        exit(False, stdout.rstrip(T_SEP), 3)

    items = ','.join(args.item).split(',')
    counts = dict(added=0, removed=0, updated=0, deduped=0)

    changed = handle(items, state, zone, False, counts, args)
    for other_zone in ZONES.keys():
        if args.solo_zone and other_zone != zone:
            excluded = handle(items, state, other_zone, True, counts, args)
            changed = changed or excluded

    if changed:
        reload_ferm(args)

    verbose = args.verbose
    msg = None
    if verbose > 0:
        subj = subject.rstrip('s')
        msg_list = []
        if counts['added'] > 0:
            msg_list.append('%d %s(s) added' % (counts['added'], subj))
        if counts['removed'] > 0:
            msg_list.append('%d %s(s) removed' % (counts['removed'], subj))
        if counts['updated'] > 0:
            msg_list.append('%d comment(s) updated' % counts['updated'])
        if counts['deduped'] > 0:
            msg_list.append('%d duplicate(s) removed' % counts['deduped'])
        msg = ', '.join(msg_list)
    exit(changed, msg, verbose)


if __name__ == '__main__':
    main()
