from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
    callback: unixy2
    type: stdout
    author: ivandeex
    short_description: condensed output
    version_added: 2.8
    description:
      - output in the style of LINUX startup logs.
    extends_documentation_fragment:
      - default_callback
    requirements:
      - set as stdout in configuration
'''

import json

from datetime import datetime
from os.path import basename
from ansible import constants as C
from ansible.module_utils._text import to_text
from ansible.utils.color import colorize, hostcolor
from ansible.plugins.callback.default import CallbackModule as CallbackModule_default

class CallbackModule(CallbackModule_default):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'unixy2'
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self):
        super(CallbackModule, self).__init__()
        self._last_role_name = ''

    def _run_is_verbose(self, result, verbosity=0):
        return ((self._display.verbosity > verbosity or result._result.get('_ansible_verbose_always', False) is True)
                and result._result.get('_ansible_verbose_override', False) is False)

    def _get_task_display_name(self, task):
        self.task_display_name = None
        display_names = task.get_name().strip().split(" : ")
        role_name = display_names[-2] if len(display_names) > 1 else ''
        task_name = display_names[-1]
        if task_name.startswith("include"):
            return
        if role_name != self._last_role_name:
            self._last_role_name = role_name
            if role_name:
                task_name = '%s - %s' % (task_name, role_name)
        self.task_display_name = task_name

    def _preprocess_result(self, result):
        self.delegated_vars = result._result.get('_ansible_delegated_vars', None)
        self._handle_exception(result._result, use_stderr=self.display_failed_stderr)
        self._handle_warnings(result._result)

    def _process_result_output(self, result, msg):
        label = ''
        if self._run_is_verbose(result):
            label = self._get_item_label(result._result) or ''
            if isinstance(label, dict):
                if 'key' in label:
                    label = label['key']
                elif 'name' in label:
                    label = label['name']
            label = ('%s' % label).strip()
            if label and label[0] not in '[({':
                label = '(%s)' % label
            if label:
                label = ' %s' % label

        task_host = result._host.get_name()
        task_result = "%s %s%s" % (task_host, msg, label)

        task_action = result._task.action
        result_msg = result._result.get('msg', '')
        if task_action in ('debug', 'assert') and msg == "ok" and result_msg:
            try:
                debug_msg = self._dump_results(result_msg, indent=4)
            except:
                debug_msg = to_text(result_msg)
            return "%s %s | %s: %s" % (task_host, msg, task_action, debug_msg)

        if self._run_is_verbose(result, verbosity=1):
            return "%s %s%s: %s" % (task_host, msg, label, self._dump_results(result._result, indent=4))

        if self.delegated_vars:
            task_delegate_host = self.delegated_vars['ansible_host']
            task_result = "%s -> %s %s%s" % (task_host, task_delegate_host, msg, label)

        if result_msg and result_msg != "All items completed":
            task_result += " | msg: " + to_text(result_msg)

        if result._result.get('stdout') and self._run_is_verbose(result, verbosity=0):
            task_result += " | stdout: " + result._result.get('stdout')

        if result._result.get('stderr'):
            task_result += " | stderr: " + result._result.get('stderr')

        return task_result

    def v2_playbook_on_task_start(self, task, is_conditional):
        self._get_task_display_name(task)
        if self.task_display_name is not None:
            ts = datetime.now().strftime("%H:%M:%S")
            self._display.display("%s.. %s" % (ts, self.task_display_name))

    def v2_playbook_on_handler_task_start(self, task):
        self._get_task_display_name(task)
        if self.task_display_name is not None:
            ts = datetime.now().strftime("%H:%M:%S")
            self._display.display("%s.. %s (via handler)... " % (ts, self.task_display_name))

    def v2_playbook_on_play_start(self, play):
        name = play.get_name().strip()
        if name and play.hosts:  # replace hyphens by endash
            msg = u"\n... %s on hosts: %s ..." % (name, ",".join(play.hosts))
        else:
            msg = u"---"
        self._display.display(msg)

    def v2_runner_on_skipped(self, result, ignore_errors=False):
        if self.display_skipped_hosts:
            self._preprocess_result(result)
            display_color = C.COLOR_SKIP
            msg = "skipped"

            task_result = self._process_result_output(result, msg)
            self._display.display("  " + task_result, display_color)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self._preprocess_result(result)
        if ignore_errors:
            msg = "failed (ignored)"
            display_color = C.COLOR_WARN
        else:
            display_color = C.COLOR_ERROR
            msg = "failed"
        task_result = self._process_result_output(result, msg)
        self._display.display("  " + task_result, display_color)

    def v2_runner_on_ok(self, result, msg="ok", display_color=C.COLOR_OK):
        self._preprocess_result(result)

        result_was_changed = ('changed' in result._result and result._result['changed'])
        if result_was_changed:
            msg = "done"
            item_value = self._get_item_label(result._result)
            if item_value:
                msg += " | item: %s" % (item_value,)
            display_color = C.COLOR_CHANGED
            task_result = self._process_result_output(result, msg)
            self._display.display("  " + task_result, display_color)
        elif self.display_ok_hosts:
            task_result = self._process_result_output(result, msg)
            self._display.display("  " + task_result, display_color)

    def v2_runner_on_start(self, host, task):
        pass  # silence warning in ansible 2.9

    def v2_runner_item_on_skipped(self, result):
        self.v2_runner_on_skipped(result)

    def v2_runner_item_on_failed(self, result):
        self.v2_runner_on_failed(result)

    def v2_runner_item_on_ok(self, result):
        self.v2_runner_on_ok(result)

    def v2_runner_on_unreachable(self, result):
        self._preprocess_result(result)  # fixes bug in ansible 2.8.1
        task_result = self._process_result_output(result, "unreachable")
        self._display.display("  " + task_result, C.COLOR_UNREACHABLE)

    def v2_on_file_diff(self, result):
        if result._task.loop and 'results' in result._result:
            for res in result._result['results']:
                self._display_diff(res)
        else:
            self._display_diff(result._result)

    def _display_diff(self, result):
        src = result.get('diff', None)
        if isinstance(src, dict) and 'prepared' in src:
            prep = src['prepared']
            if isinstance(prep, dict):
                str_prep = json.dumps(prep, sort_keys=True, indent=2, ensure_ascii=False)
                src['prepared'] = str_prep
        if src and result.get('changed', False):
            diff = self._get_diff(src)
            if diff:
                self._display.display(diff)

    def v2_playbook_on_stats(self, stats):
        self._display.display("\n- Play recap -", screen_only=True)

        hosts = sorted(stats.processed.keys())
        for h in hosts:
            t = stats.summarize(h)

            self._display.display(u"  %s : %s %s %s %s %s %s" % (
                hostcolor(h, t),
                colorize(u'ok', t['ok'], C.COLOR_OK),
                colorize(u'changed', t['changed'], C.COLOR_CHANGED),
                colorize(u'unreachable', t['unreachable'], C.COLOR_UNREACHABLE),
                colorize(u'failed', t['failures'], C.COLOR_ERROR),
                colorize(u'rescued', t['rescued'], C.COLOR_OK),
                colorize(u'ignored', t['ignored'], C.COLOR_WARN)),
                screen_only=True
            )

            self._display.display(u"  %s : %s %s %s %s %s %s" % (
                hostcolor(h, t, False),
                colorize(u'ok', t['ok'], None),
                colorize(u'changed', t['changed'], None),
                colorize(u'unreachable', t['unreachable'], None),
                colorize(u'failed', t['failures'], None),
                colorize(u'rescued', t['rescued'], None),
                colorize(u'ignored', t['ignored'], None)),
                log_only=True
            )
        if stats.custom and self.show_custom_stats:
            self._display.banner("CUSTOM STATS: ")
            # per host
            for k in sorted(stats.custom.keys()):
                if k == '_run':
                    continue
                self._display.display('\t%s: %s' % (k, self._dump_results(stats.custom[k], indent=1).replace('\n', '')))

            # print per run custom stats
            if '_run' in stats.custom:
                self._display.display("", screen_only=True)
                self._display.display('\tRUN: %s' % self._dump_results(stats.custom['_run'], indent=1).replace('\n', ''))
            self._display.display("", screen_only=True)

    def v2_playbook_on_no_hosts_matched(self):
        self._display.display("  No hosts found!", color=C.COLOR_DEBUG)

    def v2_playbook_on_no_hosts_remaining(self):
        self._display.display("  Ran out of hosts!", color=C.COLOR_ERROR)

    def v2_playbook_on_start(self, playbook):
        # TODO display whether this run is happening in check mode
        self._display.display("Executing playbook %s" % basename(playbook._file_name))

        # show CLI arguments
        if self._display.verbosity > 3:
            if context.CLIARGS.get('args'):
                self._display.display('Positional arguments: %s' % ' '.join(context.CLIARGS['args']),
                                      color=C.COLOR_VERBOSE, screen_only=True)

            for argument in (a for a in context.CLIARGS if a != 'args'):
                val = context.CLIARGS[argument]
                if val:
                    self._display.vvvv('%s: %s' % (argument, val))

    def v2_runner_retry(self, result):
        msg = "  Retrying... (%d of %d)" % (result._result['attempts'], result._result['retries'])
        if self._run_is_verbose(result):
            msg += "Result was: %s" % self._dump_results(result._result)
        self._display.display(msg, color=C.COLOR_DEBUG)
