{#-
Copyright (c) 2013, Hung Nguyen Viet

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Author: Hung Nguyen Viet <hvnsweeting@gmail.com>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>
-#}
include:
  - apt

{#- dont include java, let user decide it #}
tomcat:
  pkg:
    - installed
    - name: tomcat6
    - require:
      - cmd: apt_sources
  user:
    - present
    - name: tomcat6
    - require:
      - pkg: tomcat
  service:
    - running
    - order: 50
    - name: tomcat6
    - watch:
      - pkg: tomcat
      - file: add_catalina_env
      - file: /usr/share/tomcat6/shared
      - file: /usr/share/tomcat6/server

add_catalina_env:
  file:
    - append
    - name: /etc/environment
    - text: |
        export CATALINA_HOME="/usr/share/tomcat6"
        export CATALINA_BASE="/var/lib/tomcat6"

{# until a better fix... #}
/usr/share/tomcat6/shared:
  file:
    - symlink
    - target: /var/lib/tomcat6/shared
    - require:
      - pkg: tomcat

/usr/share/tomcat6/server:
  file:
    - symlink
    - target: /var/lib/tomcat6/server
    - require:
      - pkg: tomcat
