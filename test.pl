#!/usr/bin/perl
use 5.010;
@a = ( 1, 2, 34, 4 );
$b = 0;
do {
	shift @a;
	if ( not defined( $a[0] ) ) { $b = 1; }
	else {
		print $a[0] . "\n";
	}
} while ( $b eq 0 );
