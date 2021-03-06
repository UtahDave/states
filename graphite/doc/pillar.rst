Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`
- :doc:`/carbon/doc/index` :doc:`/carbon/doc/pillar`
- :doc:`/memcache/doc/index` :doc:`/memcache/doc/pillar`
- :doc:`/nginx/doc/index` :doc:`/nginx/doc/pillar`
- :doc:`/pip/doc/index` :doc:`/pip/doc/pillar`
- :doc:`/postgresql/doc/index` :doc:`/postgresql/doc/pillar`
- :doc:`/rsyslog/doc/index` :doc:`/rsyslog/doc/pillar`
- :doc:`/statsd/doc/index` :doc:`/statsd/doc/pillar`

Mandatory
---------

Example::

  graphite:
    hostnames:
      - graphite.example.com

.. _pillar-graphite-hostnames:

graphite:hostnames
~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/hostnames.inc

.. _pillar-graphite-initial_admin_user-username:

graphite:initial_admin_user:username
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /django/doc/initial_username.inc

.. _pillar-graphite-initial_admin_user-password:

graphite:initial_admin_user:password
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /django/doc/initial_password.inc

Optional
--------

Example::

  graphite:
    debug: False
    sentry: http://XXX:YYY@sentry.example.com/0
    db:
      password: psqluserpass
      username: psqluser
      name: psqldbname
    django_key: totalyrandomstring
    ssl: microsigns
    ssl_redirect: True
    render_noauth: False
    timeout: 30
    cheaper: 1
    idle: 240
    smtp:
      method: smtp
      server: smtp.example.com
      user: smtpuser
      from: from@example.com
      port: 25
      password: smtppassword
      encryption: 'ssl'

.. _pillar-graphite-initial_admin_user-email:

graphite:initial_admin_user:email
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /django/doc/initial_email.inc

.. _pillar-graphite-nodes:

graphite:nodes
~~~~~~~~~~~~~~

List of addresses of graphite nodes in cluster.

Default: uses only one Graphite node, no cluster (``[]``).

.. _pillar-graphite-sentry:

graphite:sentry
~~~~~~~~~~~~~~~

.. include:: /sentry/doc/dsn.inc

.. _pillar-graphite-db-username:

graphite:db:username
~~~~~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/username.inc

Default: ``graphite``.

.. _pillar-graphite-db-name:

graphite:db:name
~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/name.inc

Default: ``graphite``.

.. _pillar-graphite-db-password:

graphite:db:password
~~~~~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/password.inc

.. _pillar-graphite-db-host:

graphite:db:host
~~~~~~~~~~~~~~~~

Address of database server.

Default: uses database on the same host (``127.0.0.1``).

.. _pillar-graphite-django_key:

graphite:django_key
~~~~~~~~~~~~~~~~~~~

.. include:: /django/doc/key.inc

Default: automatically generated by Salt (``None``).

.. _pillar-graphite-smtp:

graphite:smtp
~~~~~~~~~~~~~

.. include:: /mail/doc/smtp.inc

.. _pillar-graphite-debug:

graphite:debug
~~~~~~~~~~~~~~

If set to ``True``, run with extra logging.

Default: log only high severity events (``False``).

.. _pillar-graphite-render_noauth:

graphite:render_noauth
~~~~~~~~~~~~~~~~~~~~~~

If set to ``True``, the rendered graphics can be directly access by anyone
without user authentication.

Default: requires authentication (``False``).

.. _pillar-graphite-render_allows:

graphite:render_allows
~~~~~~~~~~~~~~~~~~~~~~

List of hosts which are allowed to use remote render feature.

Default: no host allowed (``[]``).

.. _pillar-graphite-ssl:

graphite:ssl
~~~~~~~~~~~~

.. include:: /nginx/doc/ssl.inc

.. _pillar-graphite-ssl_redirect:

graphite:ssl_redirect
~~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl_redirect.inc

.. |deployment| replace:: graphite

.. include:: /uwsgi/doc/pillar.inc
