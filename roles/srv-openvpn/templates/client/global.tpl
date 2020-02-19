{% extends "client.ovpn" %}
{% block client_header %}
# CLIENT_NAME @ {{ srv_ovpn_host }} (SERVER_NAME)
client
{% endblock client_header %}
{% block client_proto %}
proto CLIENT_PROTO
remote {{ srv_ovpn_host }} SERVER_PORT
dev tun
{% endblock client_proto %}
{% block client_verify %}
verify-x509-name SERVER_CN name
{% endblock client_verify %}
{% block client_keys %}
<cert>
CLIENT_CRT
</cert>
<key>
CLIENT_KEY
</key>
{% endblock client_keys %}
