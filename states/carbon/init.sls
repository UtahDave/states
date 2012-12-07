{# TODO: send logs to GELF #}
include:
  - graphite.common
  - nrpe

carbon_logrotate:
  file:
    - managed
    - name: /etc/logrotate.d/carbon
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://carbon/logrotate.jinja2

/var/log/graphite/carbon:
  file:
    - directory
    - user: graphite
    - group: graphite
    - mode: 770
    - makedirs: True
    - require:
      - user: graphite

carbon_storage-schemas:
  file:
    - managed
    - name: /etc/graphite/storage-schemas.conf
    - template: jinja
    - user: graphite
    - group: graphite
    - mode: 440
    - source: salt://carbon/storage.jinja2
    - require:
      - user: graphite

carbon:
  file:
    - managed
    - name: /usr/local/graphite/salt-carbon-requirements.txt
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://carbon/requirements.jinja2
    - require:
      - virtualenv: graphite
  module:
    - wait
    - name: pip.install
    - pkgs: ''
    - upgrade: True
    - bin_env: /usr/local/graphite/bin/pip
    - requirements: /usr/local/graphite/salt-carbon-requirements.txt
    - install_options:
      - "--prefix=/usr/local/graphite"
      - "--install-lib=/usr/local/graphite/lib/python2.7/site-packages"
    - watch:
      - file: carbon
  cmd:
    - wait
    - name: find /usr/local/graphite -name '*.pyc' -delete
    - watch:
      - module: carbon

/etc/graphite/carbon.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://carbon/config.jinja2

{#
 # until https://github.com/graphite-project/carbon/commit/2a6dbe680c973c54c5426eb4248f90ca798595c1
 # is merged in a stable release
 #}
carbon-patch:
  file:
    - managed
    - name: /usr/local/graphite/lib/python2.7/site-packages/carbon/writer.py
    - user: root
    - group: root
    - mode: 644
    - source: salt://carbon/writer.py
    - require:
      - module: carbon

{% for instance in ('a',) %}
carbon-{{ instance }}:
  file:
    - managed
    - name: /etc/init.d/carbon-{{ instance }}
    - template: jinja
    - user: root
    - group: root
    - mode: 550
    - source: salt://carbon/init.jinja2
    - context:
      instance: a
  service:
    - running
    - name: carbon-{{ instance }}
    - require:
      - user: graphite
      - file: /var/log/graphite/carbon
      - file: /var/log/graphite
      - file: /var/lib/graphite
    - watch:
      - module: carbon
      - file: /etc/graphite/carbon.conf
      - file: carbon_storage-schemas
      - file: carbon-{{ instance }}
      - file: carbon-patch
      - cmd: carbon
{% endfor %}

/etc/nagios/nrpe.d/carbon.cfg:
  file.managed:
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://carbon/nrpe.jinja2

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/carbon.cfg
