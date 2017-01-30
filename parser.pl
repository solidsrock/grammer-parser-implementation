#!/usr/bin/perl
use 5.010;
use strict;
use Data::Dumper;
use List::MoreUtils qw(any);

#以下幾個變量由Dumper( \@Productions, \@VN, \@VT,\%firstSets,\%followSets ) . "\n";生成並修改而來
my $Productions = [
	[ 'program', 'block' ],
	[ 'block', '{',    'decls', 'stmts', '}' ],
	[ 'decls', 'decl', 'decls' ],
	[ 'decls', 'ε' ],
	[ 'decl', 'type',  'id', ';' ],
	[ 'type', 'basic', 'type\'' ],
	[ 'type\'', '[', 'num', ']', 'type\'' ],
	[ 'type\'', 'ε' ],
	[ 'stmts', 'stmt', 'stmts' ],
	[ 'stmts', 'ε' ],
	[ 'stmt', 'loc', '=', 'bool', ';' ],
	[ 'stmt', 'if', '(', 'bool', ')', 'stmt' ],
	[ 'stmt', 'if', '(', 'bool', ')', 'stmt', 'else', 'stmt' ],
	[
		'stmt', 'while', '(',     'bool', ')',    'stmt',
		'|do',  'stmt',  'while', '(',    'bool', ')',
		';'
	],
	[ 'stmt', 'break', ';' ],
	[ 'stmt', 'block' ],
	[ 'loc',  'id',    'loc\'' ],
	[ 'loc\'', '[', 'bool', ']', 'loc\'' ],
	[ 'loc\'', 'ε' ],
	[ 'bool', 'join', 'bool\'' ],
	[ 'bool\'', '||', 'join', 'bool\'' ],
	[ 'bool\'', 'ε' ],
	[ 'join', 'equality', 'join\'' ],
	[ 'join\'', '&&', 'equality', 'join\'' ],
	[ 'join\'', 'ε' ],
	[ 'equality', 'rel', 'equality\'' ],
	[ 'equality\'', '==',   'rel', 'equality\'' ],
	[ 'equality\'', '!=',   'rel', 'equality\'' ],
	[ 'equality\'', 'ε' ],
	[ 'rel',        'expr', '<',   'expr' ],
	[ 'rel',        'expr', '<=',  'expr' ],
	[ 'rel',        'expr', '>=',  'expr' ],
	[ 'rel',        'expr', '>',   'expr' ],
	[ 'rel',        'expr' ],
	[ 'expr', 'term', 'expr\'' ],
	[ 'expr\'', '+', 'term', 'expr\'' ],
	[ 'expr\'', '-', 'term', 'expr\'' ],
	[ 'expr\'', 'ε' ],
	[ 'term', 'unary', 'term\'' ],
	[ 'term\'', '*', 'unary', 'term\'' ],
	[ 'term\'', '/', 'unary', 'term\'' ],
	[ 'term\'', 'ε' ],
	[ 'unary', '!', 'unary' ],
	[ 'unary', '-', 'unary' ],
	[ 'unary', 'factor' ],
	[ 'factor', '(', 'bool', ')' ],
	[ 'factor', 'loc' ],
	[ 'factor', 'num' ],
	[ 'factor', 'real' ],
	[ 'factor', 'true' ],
	[ 'factor', 'false' ]
];
my $VN = [
	'program', 'block',  'decls',    'decl',
	'type',    'type\'', 'stmts',    'stmt',
	'loc',     'loc\'',  'bool',     'bool\'',
	'join',    'join\'', 'equality', 'equality\'',
	'rel',     'expr',   'expr\'',   'term',
	'term\'',  'unary',  'factor'
];
my $VT = [
	'{',  '}',  'id', ';',  'basic', '[',     'num',  ']',
	'=',  'if', '(',  ')',  'else',  'while', '|do',  'break',
	'||', '&&', '==', '!=', '<',     '<=',    '>=',   '>',
	'+',  '-',  '*',  '/',  '!',     'real',  'true', 'false'
];
my %firstSets = (
	'block' => ['{'],
	'term'  => [ '!', '-', '(', 'id', 'num', 'real', 'true', 'false' ],
	'if'    => ['if'],
	'equality\'' => [ '==', '!=', 'ε' ],
	'stmts'      => [ 'id', 'if', 'while', 'break', '{', 'ε' ],
	'bool\'' => [ '||', 'ε' ],
	'loc\''  => [ '[',  'ε' ],
	'decl'   => ['basic'],
	'type'   => ['basic'],
	'expr' => [ '!',  '-',  '(',     'id',    'num', 'real', 'true', 'false' ],
	'stmt' => [ 'id', 'if', 'while', 'break', '{' ],
	'term\'' => [ '*',     '/', 'ε' ],
	'expr\'' => [ '+',     '-', 'ε' ],
	'decls'  => [ 'basic', 'ε' ],
	'equality' => [ '!', '-', '(', 'id', 'num', 'real', 'true', 'false' ],
	'join'     => [ '!', '-', '(', 'id', 'num', 'real', 'true', 'false' ],
	'}'        => [],
	'type\'' => [ '[',  'ε' ],
	'unary'  => [ '!',  '-', '(', 'id', 'num', 'real', 'true', 'false' ],
	'bool'   => [ '!',  '-', '(', 'id', 'num', 'real', 'true', 'false' ],
	'join\'' => [ '&&', 'ε' ],
	'factor'  => [ '(', 'id', 'num', 'real', 'true', 'false' ],
	'loc'     => ['id'],
	'program' => ['{'],
	'rel' => [ '!', '-', '(', 'id', 'num', 'real', 'true', 'false' ]
);
my %followSets  = (
	'join'   => [ '||', ';', ')', ']' ],
	'join\'' => [ '||', ';', ')', ']' ],
	'factor' => [
		'*',  '/', '+', '-', '<',  '==', '!=', '&&',
		'||', ';', ')', ']', '<=', '>=', '>'
	],
	'unary' => [
		'*',  '/', '+', '-', '<',  '==', '!=', '&&',
		'||', ';', ')', ']', '<=', '>=', '>'
	],
	'equality' => [ '&&', '||', ';', ')', ']' ],
	'stmt' => [ 'id', 'if', 'while', 'break', '{', '}', '$', 'else', '|do' ],
	'loc' => [
		'=', 'id', 'if', 'while', 'break', '{',
		'}', '$',  '*',  '/',     '+',     '-',
		'<', '==', '!=', '&&',    '||',    ';',
		')', ']',  '<=', '>=',    '>',     'else',
		'|do'
	],
	'stmts' => [ '}', '$', 'id', 'if', 'while', 'break', '{', 'else', '|do' ],
	'block' => [ '$', 'id', 'if', 'while', 'break', '{', '}', 'else', '|do' ],
	'equality\'' => [ '&&', '||', ';', ')', ']' ],
	'decls' => [ 'id', 'if', 'while', 'break', '{', '$', '}', 'else', '|do' ],
	'expr'   => [ '<', '==', '!=', '&&', '||', ';', ')', ']', '<=', '>=', '>' ],
	'expr\'' => [ '<', '==', '!=', '&&', '||', ';', ')', ']', '<=', '>=', '>' ],
	'bool\'' => [ ';', ')',  ']' ],
	'loc\''  => [
		'=', 'id', 'if', 'while', 'break', '{',
		'}', '$',  '*',  '/',     '+',     '-',
		'<', '==', '!=', '&&',    '||',    ';',
		')', ']',  '<=', '>=',    '>',     'else',
		'|do'
	],
	'program' => [ '$' ],
	'type\'' =>
	  [ 'id', 'basic', 'if', 'while', 'break', '{', '$', '}', 'else', '|do' ],
	'bool' => [ ';', ')', ']' ],
	'type' =>
	  [ 'id', 'basic', 'if', 'while', 'break', '{', '$', '}', 'else', '|do' ],
	'term' =>
	  [ '+', '-', '<', '==', '!=', '&&', '||', ';', ')', ']', '<=', '>=', '>' ],
	'term\'' =>
	  [ '+', '-', '<', '==', '!=', '&&', '||', ';', ')', ']', '<=', '>=', '>' ],
	'decl' =>
	  [ 'basic', 'id', 'if', 'while', 'break', '{', '$', '}', 'else', '|do' ],
	'rel' => [ '==', '!=', '&&', '||', ';', ')', ']' ]
);

sub is_member {
	my $test = shift;
	return any { $_ eq $test } @_;
}

sub mergeArray {
	my $a                 = shift;
	my $currentProduction = shift;
	if ( not defined($a) ) { return 0; }
	if ( not defined($currentProduction) ) { return 0; }
	my $re = 0;
	foreach my $i (@$currentProduction) {
		if ( ( not is_member( $i, @$a ) ) and ( 'ε' ne $i ) ) {
			push( @$a, $i );
			$re++;
		}
	}
	return $re;
}

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

#对如A → w的产生式，返回selectSet(W)
sub selectSetof {
	my @sets;
	my $A = $_[0];
	do
	{   #遍歷產生式右部，直到結束或者前導集裏不包含ε爲止
		shift @_;
		my $tmp = $_[0];
		if ( defined( $_[0] ) ) {
			if ( is_member( $_[0], @$VN ) ) {
				mergeArray( \@sets, $firstSets{ $_[0] } );
			}
			if ( is_member( $_[0], @$VT ) ) {    #VT 不包含ε
				push( @sets, $_[0] );
				return @sets;
			}
			if ( 'ε' eq $_[0] ) {
				mergeArray( \@sets, $followSets{$A} );
				if ( $#sets eq 0 ) {
					push( \@sets, 'ε' );
				}
				return @sets;
			}
		}
		else {
			mergeArray( \@sets, $followSets{$A} );
			if ( $#sets eq 0 ) {
				push( \@sets, 'ε' );
			}
			return @sets;
		}
	} while ( is_member( 'ε', $firstSets{ $_[0] } ) );
	if ( not defined( $_[0] ) )
	{    #ε在Fi（w）之中，且a在Fo（A）之中。
		mergeArray( \@sets, $followSets{$A} );
		if ( $#sets eq 0 ) {
			push( \@sets, 'ε' );
		}
	}
	return @sets;
}

# 根据输入的非终结符A,终结符a,查找对应的产生式
#T[A,a]包含A → w规则，当且仅当
#a在Fi（w）之中，或
#ε在Fi（w）之中，且a在Fo（A）之中。
sub T {
	my $A            = $_[1];
	my $a            = $_[0];
	my @select       = ();
	my @SecondSelect = ();
	foreach my $P (@$Productions) {
		my @B = @$P;
		if ( $B[0] eq $A ) {
			my @selectSet = selectSetof(@B);
			if ( is_member( $a, @selectSet ) ) {
				push( @select, \@B );

				;    # 不是LL1文法，可能会有多个可用的产生式
			}

		}
	}
	return @select;
}
my @t;
my $S;
my @n;
my $lenT;
my $matchedTokens;
my @Stack = ( '#', 'program' );    # 0 代表$,表示程序结束

while (<DATA>) {
	chomp;
	@t = getTokens();
	do {
		$S = pop(@Stack);
		if ( ( $t[0] eq '#' ) and ( $S eq '#' ) ) {
			print "SUCCESS!\n";
			exit;
		}  
		if ( $t[0] ne 'saveWord' ) {
			if ( $t[0] eq $S ) {
				@t             = getTokens();
				$matchedTokens = 1;
			}
			else {
				@n = T( $t[0], $S );
				$matchedTokens = 0;
			}
		}
		else {
			if ( $t[1] eq $S ) {
				@t             = getTokens();
				$matchedTokens = 1;
			}
			else {
				@n = T( $t[1], $S );
				$matchedTokens = 0;
			}
		}
		if ( $matchedTokens eq '0' ) {
			$lenT = @n;
			if ( $lenT eq 0 ) {
				printf "FAILED\n";
				exit;
			}
			else
			{ #只取第一个产生式！
				print "PRODUCTION:\n" . Dumper( \@n ,\@Stack,$S,\@t) . "\n";
				my $tmp;
				while ( $tmp = pop( @{ $n[0] } ) ) {
					push( @Stack, $tmp );
				}
				do {
					pop(@Stack);    #移除产生式左部以及ε
				} while ( $Stack[$#Stack] eq 'ε' );
			}
		}
	} while ( $t[0] ne '#' );
}

__DATA__
{basic i;}
