{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - backup.diamond
  - cron.diamond

geminabox_backup_diamond_resources:
  file:
    - accumulated
    - name: processes
    - template: jinja
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[backup-geminabox]]
        cmdline = ^\/usr\/local\/bin\/backup-file geminabox \/var\/lib geminabox-data$
