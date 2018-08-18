#!/usr/bin/perl

use strict;
use warnings;
use feature qw{ say };
use Mojo::File;
use Data::Dumper;
use Array::Utils qw{ :all };
use Storable qw{ dclone };

my ( $encrypted, $plaintext, $dictionary ) = @ARGV;
my $plain = Mojo::File->new($plaintext)->slurp;

$Data::Dumper::Sortkeys = sub {
  my ($hash) = @_;
  return [ ( sort keys %$hash ) ];
};

$dictionary = dictionary($dictionary);

my $cipher2plain
  = { map { $_ => dclone( $dictionary->{ similarity_equivalent($_) } ) }
    cipher_words() };

my $chr_map;
$chr_map = create_chr_map($cipher2plain);
my $num = trim( $cipher2plain, $chr_map );
while (1) {
  $chr_map = create_chr_map($cipher2plain);
  my $x = trim( $cipher2plain, $chr_map );
  if ( $x != $num ) {
    $num = $x;
  }
  else {
    last;
  }
}

print_sentences($cipher2plain);
exit;

sub hash_intersection {
  my ( $a, $b ) = @_;
  my @x            = keys %$a;
  my @y            = keys %$b;
  my %intersection = map { ( $_ => undef ) } intersect( @x, @y );
  return \%intersection;
}

sub create_chr_map {
  my ($cipher2plain) = @_;

  my $chr_map = {};
  for my $cipher_word ( keys %$cipher2plain ) {
    for (
      my $letter_position = 0;
      $letter_position < length($cipher_word);
      $letter_position++
      )
    {
      my $cipher_letter = substr( $cipher_word, $letter_position, 1 );

      my %set = map { substr( $_, $letter_position, 1 ) => undef }
        keys %{ $cipher2plain->{$cipher_word} };

      if ( exists( $chr_map->{$cipher_letter} ) ) {
        $chr_map->{$cipher_letter}
          = hash_intersection( \%set, $chr_map->{$cipher_letter} );
      }
      else {
        $chr_map->{$cipher_letter} = \%set;
      }
    }
  }
  return $chr_map;
}

sub trim {
  my ( $cipher2plain, $chr_map ) = @_;

  for my $cipher_word ( keys %$cipher2plain ) {
    for my $word ( keys %{ $cipher2plain->{$cipher_word} } ) {
      for (
        my $letter_position = 0;
        $letter_position < length($cipher_word);
        $letter_position++
        )
      {
        unless (
          exists(
            $chr_map->{ substr( $cipher_word, $letter_position, 1 ) }
              ->{ substr( $word, $letter_position, 1 ) }
          )
          )
        {
          delete $cipher2plain->{$cipher_word}->{$word};
          last;
        }
      }
    }
  }

  my $sum = 0;
  for my $cipher_word ( keys %$cipher2plain ) {
    $sum += keys %{ $cipher2plain->{$cipher_word} };
  }
  return $sum;
}

sub show {
  my $cipher2plain = shift;
  for my $cipher_word ( sort keys %{$cipher2plain} ) {
    my $number_of_plaintext_possibilities
      = keys %{ $cipher2plain->{$cipher_word} };
    say sprintf "\n%s (%s): %d\n", $cipher_word,
      similarity_equivalent($cipher_word), $number_of_plaintext_possibilities;
    for my $word ( sort keys %{ $cipher2plain->{$cipher_word} } ) {
      say "\t$word";
    }
  }
}

sub similarity_equivalent {

  # MXM becomes 010, ASDF becomes 0123, AFAFA becomes 01010, etc.

  my ($word) = shift;
  my %seen;
  my @out;
  my $i = 0;

  for my $c ( split //, $word ) {
    if ( !exists( $seen{$c} ) ) {
      $seen{$c} = chr( 65 + $i );
      $i += 1;
    }
    push @out, $seen{$c};
  }
  return join( '', @out );
}

sub cipher_words {

  my $ciphertext = Mojo::File->new($encrypted)->slurp;
  $ciphertext =~ s/\s+/ /gsm;
  return split( /\s+/, $ciphertext );
}

sub dictionary {

  my $dict = shift;
  my %dictionary;
  my %similar_words;

  open my $word_file, '<', $dict;
  while ( my $line = <$word_file> ) {
    chomp $line;
    my $word = lc $line;
    next unless ( $word =~ /^\w+$/ );
    next if ( length($word) == 1 && $word !~ /[ai]/ );
    $dictionary{$word} = 1;
    $similar_words{ similarity_equivalent($word) }{$word} = undef;
  }

  is_valid( keys %dictionary );
  return \%similar_words;
}

sub is_valid {
  my %dict = map { $_ => undef } @_;
  for my $plain_word ( split /\s+/, $plain ) {
    if ( !exists( $dict{$plain_word} ) ) {
      say sprintf "Missing '%s'!!\n", $plain_word;
      exit(1);
    }
  }
}

sub print_sentences {
  my $cipher2plain = shift;
  my @matrix;
  for my $cipher_word ( cipher_words() ) {
    push @matrix, [ sort keys %{ $cipher2plain->{$cipher_word} } ];
  }

  my @output;
  my $max_index = scalar(@matrix) - 1;
  push @output, "-" for ( 0 .. $max_index );

  for ( my $c = 0; $c < scalar( @{ $matrix[0] } ); $c++ ) {
    printer( \@matrix, 0, $c, \@output );
  }
}

sub printer {
  my ( $matrix, $row, $col, $output ) = @_;

  if ( defined( $matrix->[$row][$col] ) ) {
    $output->[$row] = $matrix->[$row][$col];
  }

  if ( $row == scalar(@$matrix) - 1 ) {
    say join( " ", @$output );
    return;
  }

  for ( my $c = 0; $c < scalar( @{ $matrix->[ $row + 1 ] } ); $c++ ) {
    printer( $matrix, $row + 1, $c, $output );
  }
}
