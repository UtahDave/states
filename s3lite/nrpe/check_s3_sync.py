#!/usr/local/nagios/bin/python
# -*- encoding: utf-8

"""
NRPE script for checking age of backup files synced by s3lite
"""

# Copyright (c) 2014, Hung Nguyen Viet All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__ = 'Hung Nguyen Viet'
__maintainer__ = 'Hung Nguyen Viet'
__email__ = 'hvnsweeting@gmail.com'

import json
import logging
import os

from datetime import datetime

import boto
import nagiosplugin as nap

import bfs

log = logging.getLogger('nagiosplugin')
logging.basicConfig(level=logging.DEBUG)
NEG_INF = float('-inf')


class BackupAge(nap.Resource):
    def __init__(self, key, secret, bucket, prefix, path, minion_id):
        self.key = key
        self.secret = secret
        self.bucket = bucket
        self.prefix = prefix
        self.path = path
        self.minion_id = minion_id

    def probe(self):
        def log_and_return(value, *msg, **kwargs):
            log_func = log.__getattribute__(kwargs.get('loglevel', 'error'))
            if msg:
                log_func(*msg)

            return [nap.Metric('age', value, 'hours')]

        def fail(*msg):
            # return NEG_INF as age for all errors this will suffer
            return log_and_return(NEG_INF, *msg)

        s3 = boto.connect_s3(self.key, self.secret)
        bucket = s3.get_bucket(self.bucket)
        normalized_fn = self.path.strip(os.sep).replace(os.sep, '_')
        backup_identifier = 's3lite_{0}_{1}.json'.format(self.minion_id,
                                                         normalized_fn)

        log_path = os.path.join(self.prefix.strip('/'), backup_identifier)
        logkey = bucket.get_key(log_path)
        if logkey:
            log.debug(logkey)
            backup_mdata = json.loads(logkey.get_contents_as_string())
            try:
                log.debug(backup_mdata)
                if backup_mdata['processed'] == 0:
                    return fail('Last backup processed no-file')
                else:
                    assert backup_mdata['processed'] > 0
                    # S3 time format sample 'Wed, 06 Aug 2014 03:07:27 GMT'
                    last = datetime.strptime(logkey.last_modified,
                                             '%a, %d %b %Y %H:%M:%S %Z')
                    now = datetime.utcnow()
                    age_in_hours = (now - last).seconds / 60 / 60
                    return log_and_return(
                        age_in_hours,
                        'Last backup processed %d files',
                        backup_mdata['processed'],
                        loglevel='info',
                        )
            except KeyError:
                return fail('Malformed log file')
        else:
            return fail('Log file %s does not exist', log_path)


def main():
    import sys
    argp = bfs.common_argparser(default_config_path='/etc/s3lite.yml')
    argp.add_argument('path', type=str, help='Path used when backup')
    argp.add_argument('bucket',
                      help='s3://bucket/prefix to check uploaded file')
    argp.add_argument('-w', '--warning', metavar='HOURS', default='48',
                      help='Emit a warning if a backup file is older\
                            than HOURS')
    argp.add_argument('--timeout', default=None)
    args = argp.parse_args()

    util = bfs.Util(args.config, debug=args.log, drop_privilege=False)

    try:
        parsed = boto.urlparse.urlparse(args.bucket)
        bucket_name, prefix = parsed.netloc, parsed.path
        prefix = prefix[1:]  # prefix must not start with /

        check = nap.Check(BackupAge(util['s3']['key_id'],
                                    util['s3']['secret_key'],
                                    bucket_name,
                                    prefix,
                                    args.path,
                                    util['minion_id'],
                                    ),
                          nap.ScalarContext('age', args.warning, args.warning))
        check.main(timeout=args.timeout)
    except boto.exception.S3ResponseError as e:
        log.error('Bucket name %r is bad or does not exist.', args.bucket,
                  exc_info=True)
        sys.exit(1)
    except Exception as e:
        log.error(e, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()