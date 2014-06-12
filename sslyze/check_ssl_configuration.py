#!/usr/local/nagios/bin/python
# -*- coding: utf-8 -*-

# Copyright (c) 2014, Quan Tong Anh
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Nagios plugin to check the SSL configuration of a server.
This is calculated based on Qualys Server Rating Guide: https://www.ssllabs.com/projects/rating-guide/
"""

__author__ = 'Quan Tong Anh'
__maintainer__ = 'Quan Tong Anh'
__email__ = 'quanta@robotinfra.com'

from plugins import PluginCertInfo, PluginOpenSSLCipherSuites
from nassl import SSLV2, SSLV3, TLSV1, TLSV1_1, TLSV1_2
from datetime import datetime
import socket
import argparse
import nagiosplugin as nap


class SslConfiguration(nap.Resource):
    def __init__(self, host, port):
        self.host = host
        self.port = port

    def check(self):
        shared_settings = {
            'certinfo': 'basic', 
            'starttls': None, 
            'resum': True, 
            'resum_rate': None, 
            'http_get': True, 
            'xml_file': None, 
            'compression': True, 
            'tlsv1': True, 
            'targets_in': None, 
            'keyform': 1, 
            'hsts': None, 
            'sslv3': True, 
            'sslv2': True, 
            'https_tunnel': None, 
            'nb_retries': 4, 
            'heartbleed': True, 
            'sni': None, 
            'https_tunnel_host': None, 
            'regular': False, 
            'key': None, 
            'reneg': True, 
            'tlsv1_2': True, 
            'tlsv1_1': True, 
            'hide_rejected_ciphers': True, 
            'keypass': '', 
            'cert': None, 
            'certform': 1, 
            'timeout': 5, 
            'xmpp_to': None
        }
        
        target = (self.host, socket.gethostbyname(self.host), self.port, TLSV1_2)
        
        cert_plugin = PluginCertInfo.PluginCertInfo()
        cert_plugin._shared_settings = shared_settings
        cert_result = cert_plugin.process_task(target, 'certinfo', 'basic')
        
        is_trusted = 'OK'
        
        for c in cert_result.get_txt_result():
            if "Not After" in c:
                not_after = c.split("Not After:")[1].lstrip()
            if "Key Size" in c:
                key_size = c.split(':')[1].lstrip().split()[0]
            if "Hostname Validation" in c:
                hostname_validation = c.split(':')[1].lstrip()
            if "CA Store" in c:
                if not c.split(':')[1].lstrip().startswith('OK'):
                    is_trusted = c.split(':')[1].lstrip()
        
        expire_date = datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z")
        expire_in = expire_date - datetime.now()
        
        if hostname_validation.startswith('OK') and expire_in.days > 0 and is_trusted == 'OK':
            cipher_plugin = PluginOpenSSLCipherSuites.PluginOpenSSLCipherSuites()
            cipher_plugin._shared_settings = shared_settings
            
            protocols = ['sslv2', 'sslv3', 'tlsv1', 'tlsv1_1', 'tlsv1_2']
            
            ciphers = []
            
            for p in protocols[:]:
                cipher_result = cipher_plugin.process_task(target, p, None)
            
                for c in cipher_result.get_txt_result():
                    if 'rejected' in c:
                        protocols.remove(p)
                    if 'bits' in c:
                        ciphers.append(c.split()[1])
            
            worst_protocol = protocols[0]
            best_protocol = protocols[-1]
        
            protocol_scores = {'sslv2': 0, 'sslv3': 80, 'tlsv1': 90, 'tlsv1_1': 95, 'tlsv1_2': 100}
        
            protocol_score = (protocol_scores[worst_protocol] + protocol_scores[best_protocol]) / 2
        
            key_scores = {(0,512): 20, (512, 1024): 40, (1024, 2048): 80, (2048, 4096): 90, (4096, 16384): 100}
            
            # This must be updated when this one is merged: https://github.com/iSECPartners/sslyze/pull/70
            dh_param_strength = 1024
            
            for k, v in key_scores.iteritems():
                if k[0] <= min(int(key_size), dh_param_strength) and min(int(key_size), dh_param_strength) < k[1]:
                    key_score = key_scores[k]
                    break
        
            weakest_cipher_strength = min(ciphers)
            strongest_cipher_strength = max(ciphers)
        
            cipher_scores = {(0, 128): 20, (128, 256): 80, (256,16384): 100}
            for k, v in cipher_scores.iteritems():
                if k[0] <= int(weakest_cipher_strength) and int(weakest_cipher_strength) < k[1]:
                    weakest_cipher_score = cipher_scores[k]
                    break
        
            for k, v in cipher_scores.iteritems():
                if k[0] <= int(strongest_cipher_strength) and int(strongest_cipher_strength) < k[1]:
                    strongest_cipher_score = cipher_scores[k]
                    break
            
            cipher_score = (weakest_cipher_score + strongest_cipher_score) / 2
            
            final_score = protocol_score * 0.3 + key_score * 0.3 + cipher_score * 0.4
        else:
            final_score = 0
        return (hostname_validation, is_trusted, expire_in.days, final_score)

    def probe(self):
        check_results = self.check()
        hostname_validation = check_results[0]
        is_trusted = check_results[1]
        expire_in_days = check_results[2]
        final_score = check_results[3]

        if final_score > 0:
            return [nap.Metric('sslscore', final_score)]
        elif not hostname_validation.startswith('OK'):
            return [nap.Metric('sslscore', 0, context='serverHostname')]
        elif is_trusted != 'OK':
            return [nap.Metric('sslscore', 0, context='validationResult')]
        elif expire_in_days <= 0:
            return [nap.Metric('sslscore', 0, context='expireInDays')]


class SslSummary(nap.Summary):
    def __init__(self, host, port):
        self.host = host
        self.port = port

    def status_line(self, results):
        ssl_configuration = SslConfiguration(self.host, self.port)
        if results['sslscore'].context.name == 'serverHostname':
            return "sslscore is 0 ({0})".format(ssl_configuration.check()[0])
        elif results['sslscore'].context.name == 'validationResult':
            return "sslscore is 0 ({0})".format(ssl_configuration.check()[1])
        elif results['sslscore'].context.name == 'expireInDays':
            return "sslscore is 0 (The certificate expired {0} days ago)".format(ssl_configuration.check()[2])

    def problem(self, results):
        return self.status_line(results)


@nap.guarded
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-H', '--host', type=str, required=True)
    parser.add_argument('-p', '--port', type=int, default=443)
    parser.add_argument('-v', '--verbose', action='count', default=0, help="increase output verbosity (use up to 3 times)")
    parser.add_argument('-t', '--timeout', type=int, default=60)
    args = parser.parse_args()

    check = nap.Check(
        SslConfiguration(args.host, args.port),
        nap.ScalarContext('sslscore', nap.Range('@65:80'), nap.Range('@0:65')),
        nap.ScalarContext('serverHostname', nap.Range('@65:80'), nap.Range('@0:65')),
        nap.ScalarContext('validationResult', nap.Range('@65:80'), nap.Range('@0:65')),
        nap.ScalarContext('expireInDays', nap.Range('@65:80'), nap.Range('@0:65')),
        SslSummary(args.host, args.port))
    check.main(args.verbose, args.timeout)


if __name__ == "__main__":
    main()