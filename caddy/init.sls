{%- set default_sources = {'module' : 'caddy', 'defaults' : True, 'pillar' : True, 'grains' : ['osfinger']} %}
{% from "extra_formulas_common/load_config.jinja" import config as caddy with context -%}

{% if caddy.use is defined -%}

{% if caddy.use | to_bool -%}

{% if caddy.copr_repo|default("") | to_bool -%}

caddy_copr_repo_installation:
  pkgrepo.managed:
    - copr: {{ caddy.copr_repo }}
    required_in:
      - pkg: {{ caddy.package_name }}
    watch_in:
      - pkg: {{ caddy.package_name }}

{%- endif  %}

caddy_package_installation:
  pkg.installed:
    - name: {{ caddy.package_name }}

caddy_config_file:
  file.managed:
    - name: {{ caddy.config_file_path }}
    - source: salt://{{ slspath }}/files/config.json.jinja
    - template: jinja
    - context: {{ caddy | json }}
    - require:
      - pkg: {{ caddy.package_name }}

{%- if caddy.systemd_unit_override_template|default("") != "" %}

caddy_systemd_unit_override:
  file.managed:
    - name: /etc/systemd/{{ caddy.systemd_unit_local_path }}.d/saltstack-override.conf
    - source: salt://{{ slspath }}/{{ caddy.systemd_unit_override_template }}
    - template: jinja
    - makedirs: True
    - context: {{ caddy|json }}
    - required_in:
      - service: {{ caddy.service_name }}
    - watch_in:
      - service: {{ caddy.service_name }}
  module.run:
    - service.systemctl_reload: []
    - onchanges:
      - file: /etc/systemd/{{ caddy.systemd_unit_local_path }}.d/saltstack-override.conf

{%- endif %}

caddy_service_running:
  service.running:
    - name: {{ caddy.service_name }}
    - enable: True
    - require:
      - file: {{ caddy.config_file_path }}

{%- if caddy._certificates is defined %}

{% for path, value in caddy._certificates.items() -%}

{%- if path[-8:] == "_content" %}

caddy_tls_{{ path[:-8]|replace(".", "_") }}:
  file.managed:
    - name: {{ path[:-8] }}
    - makedirs: True
    - contents: |
        {{ value|indent(8) }}
    - required_in:
      - service: {{ caddy.service_name }}
    - watch_in:
      - service: {{ caddy.service_name }}

{%- elif path[-5:] == "_path" %}

caddy_tls_{{ path[:-5]|replace(".", "_") }}:
  file.managed:
    - name: {{ path[:-5] }}
    - source: salt://{{ value }}
    - makedirs: True
    - required_in:
      - service: {{ caddy.service_name }}
    - watch_in:
      - service: {{ caddy.service_name }}

{%- else %}

caddy_tls_{{ path|replace(".", "_") }}_unknown_method:
  test.fail_without_changes: []

{%- endif %}

{%- endfor %}

{%- endif %}

{%- else -%}

caddy_service_stopped:
  service.dead:
    - name: {{ caddy.service_name }}
    - enable: False

caddy_config_file_removal:
  file.absent:
    - name: {{ caddy.config_file_path }}
    - require:
      - service: {{ caddy.service_name }}

caddy_package_removal:
  pkg.removed:
    - name: {{ caddy.package_name }}
    - require:
      - file: {{ caddy.config_file_path }}

{%- if caddy.systemd_unit_local_path|default("") != "" %}

caddy_systemd_unit_override_cleanup:
  file.absent:
    - name: /etc/systemd/{{ caddy.systemd_unit_local_path }}.d
    - required_in:
      - pkg: {{ caddy.package_name }}

{%- endif %}

{%- if caddy._certificates is defined %}

{% for path, value in caddy._certificates.items() -%}

{%- if path[-8:] == "_content" %}

caddy_tls_{{ path[:-8]|replace(".", "_") }}_cleanup:
  file.absent:
    - name: {{ path[:-8] }}
    - required_in:
      - pkg: {{ caddy.package_name }}

{%- elif path[-5:] == "_path" %}

caddy_tls_{{ path[:-5]|replace(".", "_") }}_cleanup:
  file.absent:
    - name: {{ path[:-5] }}
    - required_in:
      - pkg: {{ caddy.package_name }}

{%- else %}

caddy_tls_{{ path|replace(".", "_") }}_unknown_method:
  test.fail_without_changes: []

{%- endif %}

{%- endfor %}

{%- endif %}

{%- endif %}

{%- else -%}

formula-caddy-is-disabled:
  test.show_notification:
    - text: |
        The caddy formula is disabled for this host
        You could enable it by setting the "use" flag in the pillar

{%- endif %}