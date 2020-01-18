#!/usr/bin/perl
use strict;
use warnings;
use IPC::Open2;
use Net::DNS;

# TODO cli args -c ferm_dir -l list_files -o openvz_file
my $ferm_dir = '{{ ferm_dir }}';
my $openvz_file = '{{ ferm_openvz_file }}';
my @list_files = qw(
{% for file in ferm_ipset_files %}
    {{ file }}
{% endfor %}
);

my $resolver = Net::DNS::Resolver->new;
my %lists;

sub fill_list {
    my ($name, $hash) = @_;
    $lists{$name} = [sort keys %$hash];
}

sub dump_lists {
    open(LISTS, '>', $openvz_file)
        or die("can't write ${openvz_file}\n");
    chmod(0640, $openvz_file)
        or die("can't chmod ${openvz_file}\n");
    for my $name (sort keys %lists) {
        my $def = sprintf("%-28s", "\@def \$${name}");
        my $value = join(' ', @{$lists{$name}});
        print LISTS "$def = ($value);\n";
    }
    close(LISTS)
}

sub parse_ports {
    my ($domain, $filename) = @_;
    my %ports;

    open(PORTS, $filename)
        or die("can't open ${filename}\n");
    for (<PORTS>) {
        s/#.*$//;
        s/^\s+|\s+$//g;
        next if /^$/;

        /^([0-9]{1,5})(?:[:-]([0-9]{1,5}))?(?:\/(tcp|udp))?$/;
        my ($start, $end, $type) = ($1, $2, $3);
        die "invalid port in $filename: $_\n" unless defined $start;

        $end = $start unless defined $end;
        next if $end < $start;
        my $range = ($start == $end) ? "$start" : "$start:$end";

        if (defined $type) {
            $ports{$type}{$range} = 1;
        } else {
            $ports{'tcp'}{$range} = 1;
            $ports{'udp'}{$range} = 1;
        }
    }
    close(PORTS);

    for my $type ('tcp', 'udp') {
        fill_list("ferm_ports_${domain}_${type}", $ports{$type}, 1);
    }
}

sub parse_hosts {
    my ($domain, $filename) = @_;
    my %hosts;

    open(HOSTS, $filename)
        or die("can't open ${filename}\n");
    for (<HOSTS>) {
        my $comment = s/#+(.*)$// ? $1 : '';
        s/^\s+|\s+$//g;
        next if /^$/;

        my $line = $_;
        $comment = '' unless defined $comment;

        if (/^([0-9]{1,3}[.]){3}[0-9]{1,3}(?:\/[0-9]{1,3})?$/) {
            $hosts{'ipv4'}{$line} = $comment;
            next;
        }

        if (/^[0-9a-fA-F:]*:[0-9a-fA-F:]*(?:\/\d+)?$/) {
            $hosts{'ipv6'}{$line} = $comment;
            next;
        }

        /^([0-9a-zA-Z_.-]+)(\/[0-9]{1,3})?(?:\/(ipv4|ipv6))?$/;
        my ($hostname, $prefixlen, $type) = ($1, $2, $3);
        die "invalid host in ${filename}: $_\n" unless defined $hostname;

        $prefixlen = '' unless defined $prefixlen;
        $type = 'any' unless defined $type;
        $comment = $hostname if $comment eq '';
        my $ok = 0;

        if ($type =~ /ipv4|any/) {
            my $query4 = $resolver->search($hostname, 'A');
            if ($query4) {
                for my $rr ($query4->answer) {
                    next unless $rr->type eq 'A';
                    my $addr = $rr->address;
                    $line = "${addr}${prefixlen}";
                    $hosts{'ipv4'}{$line} = $comment;
                    $ok = 1;
                }
            }
        }

        if ($type =~ /ipv6|any/) {
            my $query6 = $resolver->search($hostname, 'AAAA');
            if ($query6) {
                for my $rr ($query6->answer) {
                    next unless $rr->type eq 'AAAA';
                    my $addr = $rr->address;
                    $line = "${addr}${prefixlen}";
                    $hosts{'ipv6'}{$line} = $comment;
                    $ok = 1;
                }
            }
        }

        print STDERR "dns query failed: ${hostname}\n"
            unless $ok;
    }
    close(HOSTS);

    for my $type ('ipv4', 'ipv6') {
        fill_list("ferm_hosts_${domain}_${type}", $hosts{$type}, 0);
    }
}

# main
sub main {
    for my $file (@list_files) {
        my $path = "${ferm_dir}/${file}";
        $file =~ /^(ports|hosts)\.(ext|int|block)$/
            or die "invalid input: ${file}\n";
        my ($kind, $domain) = ($1, $2);
        parse_ports($domain, $path) if $kind eq 'ports';
        parse_hosts($domain, $path) if $kind eq 'hosts';
    }
    dump_lists;
}

main;
