# -*- coding: utf-8 -*-

# Use of this source code is governed by a BSD license that can be
# found in the doc/license.rst file.


__author__ = 'Tomas Neme'
__maintainer__ = 'Tomas Neme'
__email__ = 'tomas@robotinfra.com'

import glob
import os
import logging
import re

log = logging.getLogger(__name__)


def _remove_log(logfile):
    for fl in glob.glob(logfile + '*'):
        __salt__['file.remove'](fl)

def test(name, map):
    """
    Run a list of diamond collectors and make sure the right metrics are
    recorded.

    Expects diamond to have the ArchiveHandler active, which is the case
    if ``__test__`` pillar key is turned on when state ``diamond`` is applied

    :param dict map: a map in the form::

          { collectorName: { metric: boolean, metric: .. }, collectorName: ..}

        where collectorName must be just the name of the diamond collectors to
        be run, and each metric maps to a boolean that defines whether 0 is an
        acceptable value for the metric. Metrics must not prefix with the
        <hostname>.os, as this module will do that instead.
    """
    logfile = os.path.join(__opts__['cachedir'], 'diamond.archive.log')

    ret = {
        'name': 'Test Diamond',
        'changes': {},
        'result': True,
        'comment': '',
    }

    for collector, metrics in map.items():
        ret['changes'][collector] = change = {}
        _remove_log(logfile)

        if (not collector.startswith('/') and
           not collector.endswith("Collector")):
            collector += 'Collector'

        command = ('/usr/local/diamond/bin/python '
                   '/usr/local/diamond/bin/diamond -l -r {}').format(collector)

        cret = __salt__['cmd.run_all'](command)
        retcode = cret['retcode']

        if retcode != 0:
            _remove_log(logfile)
            ret['comment'] = '%s failed with retcode %d' % (command, retcode)
            ret['result'] = False
            return ret

        if 'Initialized Collector: {}'.format(collector) not in cret['stdout']:
            _remove_log(logfile)
            ret['comment'] = ('{0} was not been initialized, recheck collector'
                              ' name or its config').format(collector)
            ret['result'] = False
            return ret

        collected_metrics = {}
        log.info('Reading from %s', logfile)
        with open(logfile) as file:
            for line in file:
                metric, value, timestamp = line.split()
                collected_metrics[metric] = value
        _remove_log(logfile)
        log.debug('Collected: %s', collected_metrics)

        for metric in metrics:
            fullpath = '.'.join((__grains__['id'], 'os', metric))
            fullpathObj = re.compile(fullpath)
            found = False
            for k in collected_metrics:
                if fullpathObj.match(k):
                    found = True
                    key = k
                    break

            if found:
                log.info('Received metric: %s %s',
                         key, collected_metrics[key])
                try:
                    value = float(collected_metrics[key])
                except ValueError:
                    value = None

                if (not metrics[metric]) and (not value):
                    ret['comment'] = ('{0}: Expected non-zero value '
                                      'for the {1}').format(collector, key)
                else:
                    change[key] = {
                        'old': 'Expected to be recorded',
                        'new': 'Value = {0}'.format(collected_metrics[key])
                    }
            else:
                ret['comment'] = '{0}: {1} is not collected'.format(
                    collector, fullpath)

        if not change:
            ret['result'] = False
            return ret

    return ret
