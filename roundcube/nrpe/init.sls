{#-
Copyright (c) 2013, Hung Nguyen Viet
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

Author: Hung Nguyen Viet <hvnsweeting@gmail.com>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>

Install a roundcube Nagios NRPE checks.
-#}
include:
  - nrpe
  - apt.nrpe
  - nginx.nrpe
  - uwsgi.nrpe
  - build.nrpe
  - rsyslog.nrpe
  - postgresql.nrpe
  - postgresql.server.nrpe
{% if salt['pillar.get']('roundcube:ssl', False) %}
  - ssl.nrpe
{% endif %}

/etc/nagios/nrpe.d/roundcube.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://uwsgi/nrpe/instance.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      deployment: roundcube
      workers: {{ pillar['roundcube']['workers'] }}
{% if 'cheaper' in pillar['roundcube'] %}
      cheaper: {{ pillar['roundcube']['cheaper'] }}
{% endif %}

/etc/nagios/nrpe.d/roundcube-nginx.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://nginx/nrpe/instance.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      deployment: roundcube
      domain_name: {{ pillar['roundcube']['hostnames'][0] }}
      http_uri: /
{%- if salt['pillar.get']('roundcube:ssl', False) %}
      https: True
    {%- if salt['pillar.get']('roundcube:ssl_redirect', False) %}
      http_result: 301 Moved Permanently
    {%- endif -%}
{%- endif %}

/etc/nagios/nrpe.d/postgresql-roundcube.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://postgresql/nrpe.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      deployment: roundcube
      password: {{ pillar['roundcube']['password'] }}

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/roundcube.cfg
        - file: /etc/nagios/nrpe.d/roundcube-nginx.cfg
        - file: /etc/nagios/nrpe.d/postgresql-roundcube.cfg
