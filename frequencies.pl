#!/usr/bin/perl 

use feature qw{ say };

until ( eof(STDIN) ) { $ch = getc(STDIN) }
continue {
  $ch = lc $ch;
  $ch !~ m/[\n\. ]/ && ( $c{$ch} = defined( $c{$ch} ) ? $c{$ch} + 1 : 1 );
}

#print "$_\t$c{$_}\n" foreach ( reverse sort { $c{$a} <=> $c{$b} } ( keys %c ) );

my $frequency = join( "", reverse sort { $c{$a} <=> $c{$b} } ( keys %c ) );
say $frequency;

