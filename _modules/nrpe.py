# -*- coding: utf-8 -*-

"""
Copyright (c) 2013, Bruno Clermont
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Perform a NRPE check.
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'patate@fastmail.cn'

import logging
import re

logger = logging.getLogger(__name__)

__NRPE_RE = re.compile('^command\[([^\]]+)\]=(.+)$')

def list_checks(config_dir='/etc/nagios/nrpe.d'):
    '''
    List all available NRPE check.

    CLI Exaple::

        salt '*' nrpe.list_checks

    '''
    output = {}
    for filename in __salt__['file.find'](config_dir, type="f"):
        with open(filename, 'r') as input_fh:
            for line in input_fh:
                match = __NRPE_RE.match(line)
                if match:
                    output[match.group(1)] = match.group(2)
    return output


def run_check(check_name):
    '''
    Run a specific nagios check

    CLI Example::

        salt '*' nrpe.run_check <check name>

    '''
    checks = list_checks()
    logger.debug("Found %d checks", len(checks.keys()))
    ret = {
        'name': check_name,
        'changes': {},
    }

    if check_name not in checks:
        ret['result'] = False
        ret['comment'] = "Can't find check '{0}'".format(check_name)
        return ret

    output = __salt__['cmd.run_all'](checks[check_name], runas='nagios')
    ret['comment'] = "stdout: '{0}' stderr: '{1}'".format(output['stdout'],
                                                          output['stderr'])
    ret['result'] = output['retcode'] == 0
    return ret


def run_all_checks(return_only_failure=False):
    '''
    Run all available nagios check, usefull to check if everything is fine
    before monitoring system find it.

    CLI Example::

        salt '*' nrpe.run_all_checks

    '''
    output = {}
    for check_name in list_checks():
        check_result = run_check(check_name)
        del check_result['changes']
        del check_result['name']
        if return_only_failure:
            if not check_result['result']:
                output[check_name] = check_result
        else:
            output[check_name] = check_result
    return output
