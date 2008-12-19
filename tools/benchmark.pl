#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw/countit timethese timeit timestr/;
use lib qw{../lib/ ../t/};
use Mock;

Mock->setup_test_db;
for my $i (1..1000) {
    Mock->insert('tag',{
        id   => $i,
        name => 'perl',
    });
}

my $t = countit 2 => sub {
    Mock->search('tag')->all
};

print timestr($t), "\n";
