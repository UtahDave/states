{#
 Common stuff for all shinken components
 #}
{% set version = "1.2.4" %}
include:
  - virtualenv
  - pip
  - python.dev
  - apt

{# common to all shinken daemons #}

/usr/local/bin/shinken-ctl.sh:
  file:
    - managed
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://shinken/shinken-ctl.jinja2

{% for dirname in ('log', 'lib') %}
/var/{{ dirname }}/shinken:
  file:
    - directory
    - user: shinken
    - group: shinken
    - mode: 770
    - require:
      - user: shinken
{% endfor %}

/etc/shinken:
  file:
    - directory
    - user: shinken
    - group: shinken
    - mode: 550
    - require:
      - user: shinken

/usr/local/shinken/src:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755

shinken:
  virtualenv:
    - manage
    - name: /usr/local/shinken
    - no_site_packages: True
    - require:
      - module: virtualenv
{%- if 'files_archive' in pillar %}
  archive:
    - extracted
    - name: /usr/local/shinken/src
    - source: {{ pillar['files_archive'] }}/mirror/shinken-{{ version }}.tar.gz
    - source_hash: md5=f674ee59a627342925d79b36a143a488
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/shinken/src/shinken-{{ version }}
    - require:
      - file: /usr/local/shinken/src
{%- endif %}
  file:
    - managed
    - name: /usr/local/shinken/salt-requirements.txt
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://shinken/requirements.jinja2
    - context:
      version: {{ version }}
    - require:
      - virtualenv: shinken
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/shinken/bin/pip
    - requirements: /usr/local/shinken/salt-requirements.txt
    - require:
{%- if 'files_archive' in pillar %}
      - archive: shinken
{%- endif %}
      - virtualenv: shinken
    - watch:
      - file: shinken
      - pkg: python-dev
      - user: shinken
  user:
    - present
    - shell: /bin/false
    - home: /var/lib/shinken
    - gid_from_name: True
