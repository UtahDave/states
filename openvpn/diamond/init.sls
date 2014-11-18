{#-
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

Author: Bruno Clermont <bruno@robotinfra.com>
Maintainer: Viet Hung Nguyen <hvn@robotinfra.com>
-#}
include:
  - diamond
  - openvpn.static
  - rsyslog.diamond

openvpn_diamond_collector:
  file:
    - managed
    - name: /etc/diamond/collectors/OpenVPNCollector.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://openvpn/diamond/config.jinja2
    - context:
      instances:
{%- for tunnel in pillar['openvpn'] %}
        {{ tunnel }}: file:///var/lib/openvpn/{{ tunnel }}.log
{%- endfor %}
    - require:
      - file: /etc/diamond/collectors
{%- for tunnel in pillar['openvpn'] %}
      - service: openvpn-{{ tunnel }}
{%- endfor %}
    - watch_in:
      - service: diamond

openvpn_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require:
{%- for tunnel in pillar['openvpn'] %}
      - service: openvpn-{{ tunnel }}
{%- endfor %}
    - text:
      - |
        [[openvpn]]
        exe = ^\/usr\/sbin\/openvpn$
