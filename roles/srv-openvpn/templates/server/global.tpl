{% extends "server.conf" %}
{% block server_proto %}
proto SERVER_PROTO6
port SERVER_PORT
dev tun
{% endblock server_proto %}
{% block server_subnet %}
server SUBNET4_NET SUBNET4_MASK
IF_IPV6 server-ipv6 SUBNET6
{% endblock server_subnet %}
{% block server_redirect %}
{% set gw_comment = srv_ovpn_redirect_gateway |bool |ternary('','#') %}
{{ gw_comment }}push "redirect-gateway def1 bypass-dhcp"
IF_IPV6 {{ gw_comment }}push "route-ipv6 2000::/3"
IF_IPV6 {{ gw_comment }}push "redirect-gateway ipv6"
{% endblock server_redirect %}
{% block fast_io %}
IF_UDP fast-io
{% endblock fast_io %}
{% block server_certs %}
ca ca.crt
cert servers/SERVER_NAME/server.crt
key servers/SERVER_NAME/server.key
{% endblock server_certs %}
{% block server_paths %}
config servers/SERVER_NAME/routes
client-config-dir servers/SERVER_NAME/configs
ifconfig-pool-persist {{ srv_ovpn_run_dir }}/SERVER_NAME.pool
status {{ srv_ovpn_run_dir }}/SERVER_NAME.status 10
{% endblock server_paths %}
