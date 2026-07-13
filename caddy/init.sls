{%- set default_sources = {'module' : 'caddy', 'defaults' : True, 'pillar' : False, 'grains' : []} %}
{%- from "extra_formulas_common/load_config.jinja" import config as caddy with context %}

caddy-formula-test:
  test.show_notification:
    - name: Testing notifications
    - text: |
        Just trying the notification state for now
        eager to do fancier things