{#- BBB don't work on != lucid -#}
{%- if grains['lsb_codename'] == 'lucid' %}
include:
  - bbb

test:
  nrpe:
    - run_all_checks
    - order: last
{%- endif -%}
