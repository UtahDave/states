{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{% set build_dir = '/usr/lib/erlang/lib' %}

include:
  - erlang

erlang_mod_pgsql:
  archive:
    - extracted
    - name: {{ build_dir }}
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - source: {{ files_archive }}/mirror/erlang_mod_pgsql-1.0.tar.gz
{%- else %}
    - source: https://github.com/lamoanh/pgsql/archive/v1.0.tar.gz
{%- endif %}
    - source_hash: md5=757dbadf64257426fbc2e3127075e9a6
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ build_dir }}/pgsql-1.0
    - require:
      - pkg: erlang
  cmd:
    - run
    - name: ./build.sh
    - cwd: /{{ build_dir }}/pgsql-1.0 {# cwd here because build.sh use relative path #}
    - user: root
    - unless: test -f {{ build_dir }}/pgsql-1.0/ebin/pgsql.beam
    - require:
      - archive: erlang_mod_pgsql

