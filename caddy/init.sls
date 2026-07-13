{%- set default_sources = {'module' : 'caddy', 'defaults' : True, 'pillar' : False, 'grains' : []} %}
{%- from "extra_formulas_common/load_config.jinja" import config as caddy with context %}

{% if caddy.use is defined -%}

{% if caddy.use | to_bool -%}

caddy-install-package:
  pkg.installed:
    - name: {{ caddy.package_name }}

{%- else -%}

caddy-uninstallation:
  test.show_notification:
    - name: Uninstallation not implemented
    - text: The uninstallation is not implemented yet. Contributions are welcome

{%- endif %}

{%- endif %}