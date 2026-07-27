{%- set default_sources = {'module' : 'caddy', 'defaults' : True, 'pillar' : True, 'grains' : ['osfinger']} %}
{% from "extra_formulas_common/load_config.jinja" import config as caddy with context -%}

{% if caddy.use is defined -%}

{% if caddy.use | to_bool -%}

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

caddy_service_running:
  service.running:
    - name: {{ caddy.service_name }}
    - enable: True
    - require:
      - file: {{ caddy.config_file_path }}

{%- if caddy.systemd_unit_override_template|default("") != "" %}

caddy_systemd_unit_override:
  file.managed:
    - name: /etc/systemd/{{ caddy.systemd_unit_local_path }}.d/saltstack-override.conf
    - source: salt://{{ slspath }}/{{ caddy.systemd_unit_override_template }}
    - template: jinja
    - makedirs: True
    - context: {{ caddy|json }}
    - required_on:
      - service: {{ caddy.service_name }}
    - watch_on:
      - service: {{ caddy.service_name }}

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
    - required_on:
      - pkg: {{ caddy.package_name }}

{%- endif %}

{%- endif %}

{%- else -%}

formula-caddy-is-disabled:
  test.show_notification:
    - text: |
        The caddy formula is disabled for this host
        You could enable it by setting the "use" flag in the pillar

{%- endif %}