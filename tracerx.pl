#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'uninitialized';

use Pod::Usage;

our $Script  = 'tracerx.pl';
our $VERSION = '0.01';

$| = 1;

my $show_line   = 0;
my $file_filter = '';
my $func_filter = '';
my $func_ignore = '';

while ($ARGV[0] =~ /^-/) {
    local $_ = shift;

    if (/^(?:-h|-\?|--help)/) {
        pod2usage(0);
    } elsif (/^-l/) {
        $show_line = 1;
    } elsif (/^-f/) {
        $file_filter = shift;
    } elsif (/^-s/) {
        $func_filter = shift;
    } elsif (/^-i/) {
        $func_ignore = shift;
    } else {
        die "Unknown option: $_\n";
    }
}

my $obj = $ARGV[0];
my (%SYM, %FUNC);

print "Loading symbol table...\n";

open(NM, "nm -l $obj|") or die "Cannot open nm: $!\n";

while (<NM>) {
    my ($addr, $name, $file) = 
        m/ ^ (?:0x)? ( [0-9a-fA-F]+ )
                \s+
            [^\s]*
                \s+
            ( [^\s]+ )
                \s*
            ( [^\s]+ )? $ /x  or next;

    next  if $file_filter && $file !~ /$file_filter/;
    next  if $func_filter && $name !~ /$func_filter/;
    next  if $func_ignore && $name =~ /$func_ignore/;

    $SYM{hex($addr)} = { name => $name, file => $file };

    $FUNC{$name} = $file  if $name && $file;
}

close(NM);


my $cmd = join(' ', @ARGV)." 2>&1 |";

print "Starting $cmd\n"; 

open(OBJ, $cmd) or die "Cannot start $cmd: $!\n";

my $indent;

while (<OBJ>) {
    my ($action, $addr) = 
        m/ ^ (?: nginx: )? \s+ (enter|exit) \s+ (?:0x)? ( [0-9a-fA-F]+ ) /x
            or print && next;

    next  unless $SYM{ hex($addr) }->{name}; # ignoring unknown functions

    if ($action eq 'enter') {
        $indent .= '   '; 

        my $buf = $indent. $SYM{ hex($addr) }->{name};

        if ($show_line) { 
            $buf .= " " x (79 - length($buf))  if length($buf) < 79;
            $buf .= " ". $SYM{ hex($addr) }->{file} || 
                            $FUNC{ $SYM{ hex($addr) }->{name} };
        }

        print "$buf\n";

    } elsif ($action eq 'exit') {
        substr($indent, -3, 3, '');
    }
}

close(OBJ);

1;
__END__

=head1 NAME

tracerx.pl - runtime call tracer for nginx

=head1 DESCRIPTION

Simple runtime call tracer. Uses profiling instrument functions and symbol
table to record and print calls. Useful for complex problems and learning 
nginx internals.

Something similar can be done with gdb and lots of breakpoints, but 
annoyingly slowly. 

=head1 INSTALLATION

Download and compile nginx with C<ngx_trace> module:

    % ./configure --add-module=/path/to/ngx_trace  && make

This will enable debug symbols and instrument functions for gcc. 
Next, make sure binary works and can print its own version:

    % ./objs/nginx -V

Prepare environment to run nginx from:

    % mkdir mynginx
    % mkdir mynginx/logs
    % cp -r conf mynginx/
    % cp -r html mynginx/

Edit your new C<nginx.conf>, make sure it runs single process in foreground 
and uses ports that don't require privileges to bind to:

    daemon off;
    master_process off;
    
    ...
    
    http {
        server {
            listen 5678;
    ...

I find it useful to print errors to stderr as well:

    error_log /dev/stderr;

And now you can start playing with F<tracerx.pl>:

    % /path/to/ngx_trace/tracerx.pl ./objs/nginx -p mynginx

=head1 SYNOPSIS

tracengx.pl [OPTIONS] COMMAND

=head1 OPTIONS

=over 8

=item B<-l>

print filename and line number saved from C<nm -l>

=item B<-s PATTERN>

print calls matching specified regex pattern only

=item B<-i PATTERN>

ignore calls matching regex pattern

=item B<-f PATTERN>

print calls if filename matches pattern

=back

=head1 EXAMPLES

Show all calls within F<src/http> and F<src/event> modules:

    % ./tracerx.pl -f 'src/http|src/event' ./objs/nginx -p mynginx

Show calls within http and ignore all calls containing _log_ in function
name:

    % ./tracerx.pl -f 'src/http' -i '_log_' ./objs/nginx -p mynginx

=head1 AUTHOR

Alexandr Gomoliako <zzz@zzz.org.ua>

=head1 LICENSE

Copyright 2011 Alexandr Gomoliako. All rights reserved.

This module is free software. It may be used, redistributed and/or modified 
under the same terms as Perl itself.

=cut


