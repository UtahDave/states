{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - clamav
  - clamav.nrpe
  - clamav.diamond
  - doc

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}

{%- call test_cron() %}
- sls: clamav
- sls: clamav.nrpe
- sls: clamav.diamond
{%- endcall %}

test:
  monitoring:
    - run_all_checks
    - wait: 60
    - order: last
    - require:
      - cmd: test_crons
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('clamav') }}
    {{ diamond_process_test('freshclam') }}
    - require:
      - sls: clamav
      - sls: clamav.diamond
  qa:
    - test
    - name: clamav
    - pillar_doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
