{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

Author: Lam Dang Tung <lam@robotinfra.com>
Maintainer: Quan Tong Anh <quanta@robotinfra.com>
-#}
{%- from 'diamond/macro.jinja2' import uwsgi_diamond with context %}
{%- call uwsgi_diamond('gitlab') %}
- postgresql.server.diamond
- redis.diamond
- rsyslog.diamond
- ssh.server.diamond
{%- endcall %}

gitlab_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[gitlab]]
        cmdline = ^\/bin\/sh \.\/bin\/background_jobs start_no_deamonize$
