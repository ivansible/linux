#!/usr/bin/perl
use strict;
use warnings;
use IPC::Open2;
use Net::DNS;

# TODO cli args -c ferm_dir -l list_files
# -c ferm_dir
my $ferm_dir = '{{ ferm_dir }}';
# -l list_files
my @list_files = qw(
{% for file in ferm_ipset_files %}
    {{ file }}
{% endfor %}
);

my $ipset = '/sbin/ipset';

my $resolver = Net::DNS::Resolver->new;
my $tempset = '';

END {
    `$ipset destroy $tempset` if $tempset;
}

$| = 1;

sub run {
    my ($cmd, $input) = @_;
    my $pid = open2(my $stdout, my $stdin, "($cmd) 2>&1")
        or die "cannot run ${cmd}\n";
    print $stdin $input;
    close $stdin or die;
    waitpid $pid, 0;
    my $output = '';
    while (<$stdout>) { $output .= $_; }
    close $stdout or die;
    die "error: ${output}" if $?;
    return $output;
}

sub make_tempset {
    for (my $try = 1; $try < 100; $try++) {
        my $name = "ferm-tmp${try}";
        my $out = `ipset create $name bitmap:port range 1-2 2>&1`;
        unless ($?) {
            $tempset = $name;
            return;
        }
    }
    die "cannot create temporary ipset\n";
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
        my $range = ($start == $end) ? "$start" : "$start-$end";

        if (defined $type) {
            $ports{$type}{$range} = 1;
        } else {
            $ports{'tcp'}{$range} = 1;
            $ports{'udp'}{$range} = 1;
        }
    }
    close(PORTS);

    for my $type ('tcp', 'udp') {
        my $hash = $ports{$type};
        my $name = "ferm-ports-${domain}-${type}";
        my $opts = "bitmap:port range 0-65535";
        my @cmd = (
            "create -exist $name $opts",
            "destroy $tempset",
            "create $tempset $opts",
        );
        push @cmd, "add $tempset $_"
            for (sort keys %$hash);
        push @cmd, "swap $tempset $name";
        run "$ipset -", join("\n", @cmd) . "\n";
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
        my $hash = $hosts{$type};
        my $family = ($type eq 'ipv4') ? 'inet' : 'inet6';
        my $name = "ferm-hosts-${domain}-${type}";
        my $opts = "hash:net family $family comment";
        my @cmd = (
            "create -exist $name $opts",
            "destroy $tempset",
            "create $tempset $opts",
        );
        for my $line (sort keys %$hash) {
            my $comment = $$hash{$line};
            $comment =~ s/[\"\'\s]+/ /g;  # quotes are disallowed
            $comment =~ s/^\s+|\s+$//g;
            $line .= " comment \"$comment\"" if $comment;
            push @cmd, "add $tempset $line";
        }
        push @cmd, "swap $tempset $name";
        run "$ipset -", join("\n", @cmd) . "\n";
    }
}

# main
sub main {
    make_tempset;
    for my $file (@list_files) {
        my $path = "${ferm_dir}/${file}";
        $file =~ /^(ports|hosts)\.(ext|int|block)$/
            or die "invalid input: ${file}\n";
        my ($kind, $domain) = ($1, $2);
        parse_ports($domain, $path) if $kind eq 'ports';
        parse_hosts($domain, $path) if $kind eq 'hosts';
    }
}

main;
