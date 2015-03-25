{#- Usage of this is governed by a license that can be found in doc/license.rst
-*- ci-automatic-discovery: off -*-

run these stuff AFTER integration.py to make sure them do not be deleted/changed by integration.py
-#}

ci-agent:
  user:
    - present
  file:
    - name: /home/ci-agent/.ssh
    - directory
    - user: ci-agent
    - group: ci-agent
    - mode: 750
    - require:
      - user: ci-agent

/home/ci-agent/.ssh/id_rsa:
  file:
    - managed
    - name: /home/ci-agent/.ssh/id_rsa
    - user: ci-agent
    - group: ci-agent
    - mode: 400
    - contents: |
        {{ salt['pillar.get']('salt_ci:agent_privkey')|indent(8) }}
    - require:
      - file: ci-agent

/home/ci-agent/.ssh/known_hosts:
  file:
    - managed
    - user: ci-agent
    - group: ci-agent
    - mode: 644
    - contents: |
        {{ salt['pillar.get']('salt_ci:host_key')|indent(8) }}
    - require:
      - file: ci-agent

{%- set result_file = '/home/ci-agent/result.xml' -%}
{%- set test_files = salt['file.find']('/root/salt/', name='TEST-*-salt.xml') %}

openssh-client:
  pkg:
    - installed

test_result:
  file:
{%- if test_files -%}
    {#- integration.py worked #}
    - rename
    - source: {{ test_files[0] }}
{%- else -%}
    {#- integration.py failed #}
    - managed
    - source: salt://test/jenkins/result/failure.xml
{%- endif %}
    - name: {{ result_file }}
  cmd:
    - run
    - user: ci-agent
{%- set ssh_port = salt['pillar.get']('salt_ci:ssh_port', 22) %}
    - name: scp -P {{ ssh_port }} {{ result_file }} ci-agent@{{ grains['master'] }}:/home/ci-agent/{{ grains['id'] }}-result.xml
    - path: {{ result_file }}
    - require:
      - file: test_result
      - file: /home/ci-agent/.ssh/known_hosts
      - file: /home/ci-agent/.ssh/id_rsa
      - pkg: openssh-client

scp_logs_to_master:
  cmd:
    - run
    - name: scp -P {{ ssh_port }} /tmp/*.xz ci-agent@{{ grains['master'] }}:/home/ci-agent/
    - user: ci-agent
    - require:
      - file: /home/ci-agent/.ssh/known_hosts
      - file: /home/ci-agent/.ssh/id_rsa
      - pkg: openssh-client
