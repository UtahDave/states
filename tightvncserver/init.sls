{#-
Copyright (C) 2013 the Institute for Institutional Innovation by Data
Driven Design Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE  MASSACHUSETTS INSTITUTE OF
TECHNOLOGY AND THE INSTITUTE FOR INSTITUTIONAL INNOVATION BY DATA
DRIVEN DESIGN INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the names of the Institute for
Institutional Innovation by Data Driven Design Inc. shall not be used in
advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from the
Institute for Institutional Innovation by Data Driven Design Inc.

Author: Lam Dang Tung <lamdt@familug.org>
Maintainer: Lam Dang Tung <lamdt@familug.org>

Install TightVNC - Virtual Network Computing.
-#}
{%- set wm = salt['pillar.get']('tightvncserver:wm', 'fluxbox') %}
{%- set user = salt['pillar.get']('tightvncserver:user', 'vnc') %}
{%- set user_passwd = salt['pillar.get']('tightvncserver:user_passwd', 'vnc') %}
{%- set home = "/home/" + user %}
{%- set vnc_passwd = salt['pillar.get']('tightvncserver:password') %}

include:
  - apt
  - logrotate
  - {{ wm }}

tightvncserver_depends:
  pkg:
    - installed
    - name: xfonts-base
    - require:
      - cmd: apt_sources

tightvncserver:
  user:
    - present
    - name: {{ user }}
    - home: /home/{{ user }}
{%- if salt['pillar.get']('tightvncserver:sudo', False) %}
    - groups:
      - sudo
{%- endif %}
    - shell: /bin/bash
  module:
    - wait
    - name: shadow.set_password
    - m_name: {{ user }}
    - password: {{ salt['password.encrypt_shadow'](user_passwd) }}
    - watch:
      - user: tightvncserver
  pkg:
    - installed
    - require:
      - cmd: apt_sources
      - pkg: tightvncserver_depends
      - pkg: {{ wm }}
      - user: tightvncserver
  file:
    - managed
    - name: {{ home }}/.vnc/xstartup
    - mode: 550
    - user: {{ user }}
    - group: {{ user }}
    - source: salt://tightvncserver/xstartup.jinja2
    - template: jinja
    - require:
      - pkg: tightvncserver
      - file: {{ home }}/.vnc
    - context:
      wm: {{ wm }}
  cmd:
    - wait
    - name: echo -n `echo "{{ vnc_passwd }}" | tightvncpasswd -f` > .vnc/passwd
    - cwd: {{ home }}
    - user: {{ user }}
    - require:
      - file: tightvncserver
      - file: {{ home }}/.vnc
    - watch:
      - pkg: tightvncserver
  service:
    - running
    - name: tightvncserver
    - require:
      - pkg: tightvncserver
      - file: {{ home }}/.vnc/passwd
    - watch:
      - debconf: tightvncserver
      - cmd: tightvncserver
      - file: tightvncserver
      - file: /etc/init/tightvncserver.conf
  debconf:
    - set
    - name: x11-common
    - data:
        'x11-common/xwrapper/allowed_users': {'type': 'string', 'value': 'console'}
    - require:
      - pkg: apt_sources
      - pkg: tightvncserver

{{ home }}/.vnc:
  file:
    - directory
    - user: {{ user }}
    - group: {{ user }}
    - dir_mode: 755
    - require:
      - user: tightvncserver

/etc/logrotate.d/tightvncserver:
  file:
    - managed
    - source: salt://tightvncserver/logrotate.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: logrotate
      - pkg: tightvncserver
    - context:
      home: {{ home }}

/etc/init/tightvncserver.conf:
  file:
    - managed
    - user: root
    - group: root
    - mode: 440
    - source: salt://tightvncserver/upstart.jinja2
    - template: jinja
    - context:
      user: {{ user }}
      home: {{ home }}
    - require:
      - user: {{ user }}

{{ home }}/.vnc/passwd:
  file:
    - managed
    - user: {{ user }}
    - group: {{ user }}
    - mode: 600
    - watch:
      - cmd: tightvncserver
    - require:
      - user: tightvncserver
      - file: {{ home }}/.vnc
{%- if wm == "fluxbox" %}
      - file: {{ home }}/.fluxbox/menu

vnc_change_permission_home_fluxbox:
  file:
    - directory
    - name: {{ home }}/.fluxbox
    - user: {{ user }}
    - group: {{ user }}
    - dir_mode: 755
    - require:
      - user: tightvncserver

{{ home }}/.fluxbox/menu:
  file:
    - managed
    - user: {{ user }}
    - group: {{ user }}
    - mode: 444
    - source: salt://fluxbox/menu.jinja2
    - template: jinja
    - require:
      - pkg: fluxbox
      - file: vnc_change_permission_home_fluxbox
{%- endif %}
