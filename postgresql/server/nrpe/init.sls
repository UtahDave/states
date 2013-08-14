{#
 Nagios NRPE check for PostgreSQL Server
#}
{% set version="9.2" %}

include:
  - nrpe
  - postgresql.nrpe
  - apt.nrpe
  - gsyslog.nrpe
{% if salt['pillar.get']('postgresql:ssl', False) %}
  - ssl.nrpe
{% endif %}

/etc/nagios/nrpe.d/postgresql-diamond.cfg:
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
      deployment: diamond
      version: {{ version }}
      password: {{ salt['password.pillar']('postgresql:diamond') }}

/etc/nagios/nrpe.d/postgresql.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://postgresql/server/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      version: {{ version }}

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/postgresql.cfg
        - file: /etc/nagios/nrpe.d/postgresql-diamond.cfg
