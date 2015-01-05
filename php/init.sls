{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

Author: Viet Hung Nguyen <hvn@robotinfra.com>
Maintainer: Dang Tung Lam <lam@robotinfra.com>
-#}
include:
  - apt

php:
  pkgrepo:
    - managed
{%- if salt['pillar.get']('files_archive', False) %}
    - name: deb {{ salt['pillar.get']('files_archive', False)|replace('https://', 'http://') }}/mirror/lucid-php5 {{ grains['lsb_distrib_codename'] }} main
    - key_url: salt://php/key.gpg
{%- else %}
    - ppa: l-mierzwa/lucid-php5
{%- endif %}
    - file: /etc/apt/sources.list.d/lucid-php5.list
    - require:
      - pkg: apt_sources
