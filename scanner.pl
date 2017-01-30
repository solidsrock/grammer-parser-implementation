#!/usr/bin/perl
use 5.010;
use strict;
use Data::Dumper;

# scanner

#返回一个长度为二的一维数组，第一个元素为终结符的类型，第二个元素为终结符本身
sub getTokens() {
	my %lexTable = (
		'saveWord' =>
'^(;|if(\\b)|basic(\\b)|else(\\b)|while(\\b)|do(\\b)|break(\\b)|true(\\b)|false(\\b)|==|>=|<=|<|>|!=|\\+|\\-|\\*|\\/|!|&&|\\|\\||=|\\[|\\]|\\(|\\)|\\{|\\})',
		'basic' => "^(int|char|float)\\s",
		'id'    => "^([a-zA-Z][a-zA-Z\\d]*)",
		'real'  => '^(\\d+\.\\d+)',
		'num'   => '^(\\d+)'
	);
	$_ =~ s/^\s+//;    #删除不必要的空格
	foreach my $key ( keys %lexTable ) {
		if ( $_ =~ /$lexTable{$key}/ ) {
			$_ = substr( $_, length($1) );
			return ( $key, $1 );
		}
	}
	return ( '#', 0 );
}

# end of scanner

while ( <DATA> ) {
	chomp;
	my @tmp = getTokens;
	do {
		print Dumper( \@tmp ) . "\n";
		@tmp = getTokens();
	} while ( $tmp[0] ne '#' );
}

__DATA__
{
	int i;
	int j;
	int if1;
	char do2;
	j=1;
	i=5;
	if1=j/i;
	while(i>j){
		j=j+1;
		print j;
	}
}
