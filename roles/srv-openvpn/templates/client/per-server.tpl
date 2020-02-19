{% extends "client.ovpn" %}
{% block client_header %}
# CLIENT_NAME @ {{ server_host }} ({{ server_name }})
client
{% endblock client_header %}
{% block client_keys %}
<cert>
CLIENT_CRT
</cert>
<key>
CLIENT_KEY
</key>
{% endblock client_keys %}
