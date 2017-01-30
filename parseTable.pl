#!/usr/bin/perl
use 5.010;
use strict;
use Data::Dumper;
use List::MoreUtils qw(any)
  ; #需要用到list util工具包 ，ubuntu 下运行 sudo apt-get install liblist-moreutils-perl 安装
my @VN;    #非终结符 数组
my @VT;
my @Productions
  ; #二維數組儲存產生式，每行一條產生式，第一列元素爲產生式左部，後面的元素爲產生式右部

sub loadGrammar {
	my $currentProductionuf;

	#讀取文法，並轉換爲相應的數據結構
	while ( $currentProductionuf = <DATA> ) {
		chomp($currentProductionuf);
		my @tmp =
		  split( '→', $currentProductionuf );  #分隔非终结符和产生式
		$tmp[0] =~ s/^\s+|\s+$//g;
		$tmp[1] =~ s/^\s+|\s+$//g;  #消除多余的空格，与trim功能一样
		if ( not any { $_ eq $tmp[0] } @VN ) {
			push( @VN, $tmp[0] )
			  ;    #如果的新的非終結符，則將其加入VN數組
		}
		my @tmpProduces = split( '\\s\\|\\s', $tmp[1] );
		for (@tmpProduces) {
			s/^\s+|\s+$//g;    #移除產生式右部多餘的空格
			my @tmpSplitedProduces;
			$tmpSplitedProduces[0] = $tmp[0];
			push( @tmpSplitedProduces, split('\\s+') );
			push( @Productions,        \@tmpSplitedProduces );
		}
	}

	#遍歷Productions ，提取終結符存放於 VT中
	for (@Productions) {
		my @production = @$_;
		for (@production) {
			my $tmp = $_;
			if (    ( not any { $_ eq $tmp } @VN )
				and ( not any { $_ eq $tmp } @VT ) )
			{
				push( @VT, $tmp );
			}
		}
	}
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

sub is_member {
	my $test = shift;
	return any { $_ eq $test } @_;
}

my %firstSets;

sub FirstSet {
	my $currentToken = $_[0]
	  ; #如果還沒有創建該符號的前導字符集，則先創建一個空的集合
	if ( not exists( $firstSets{$currentToken} ) ) {
		my @emptyArray;
		$firstSets{$currentToken} = \@emptyArray;
	}
	else {
		return 0;
	}
	my $countChanged = 0;
	if ( any { $_ eq $currentToken } @VN ) {  #如果當前符號是非終結符
		for (@Productions) {                  #遍歷所有產生式，
			my @currentProduction = @$_;
			if ( $currentProduction[0] eq $currentToken )
			{    #對所有左部爲當前符號的產生式
				    #my $test=${$_}[1];
				my $firstRightToken = $currentProduction[1];
				if (
					( any         { $_ eq $firstRightToken } @VT )
					and ( not any { $_ eq $firstRightToken }
						@{ $firstSets{$currentToken} } )
				  )
				{ #如果產生式右部第一個符號爲终结符且不在當前符號的前導字符集中
					$countChanged +=
					  push( $firstSets{$currentToken}, $firstRightToken );
				}
				else {
					do {
						$firstRightToken = $currentProduction[1];
						if ( $firstRightToken eq $currentToken ) {
							return $countChanged;
						}
						if ( not exists( $firstSets{$firstRightToken} ) )
						{ #如果右部第一個符號的前導符號集還沒有計算，則先計算之
							$countChanged += FirstSet( ($firstRightToken) );
						}
						$countChanged += mergeArray(
							$firstSets{$currentToken},
							$firstSets{$firstRightToken}
						);
						shift;
					  } while ( any { $_ eq 'ε' }
						@{ $firstSets{$firstRightToken} } )
					  ; #循環計算產生式右部的每一個符號，直到符合的前導集裏沒有'ε'
				}
			}
		}
	}
	else {
		$countChanged += push( @{ $firstSets{$currentToken} }, $currentToken );
	}
	return $countChanged;
}
my %followSets =
  ( 'program' => ['$'] );    #開始符號的後續字符爲結束符

sub FollowSet {
	my $countChanged = 0;
	for (@Productions) {
		my @currentProduction = @$_;
		my $len               = @currentProduction;
		for ( my $i = 1 ; $i < $len ; $i++ ) {
			if ( is_member( $currentProduction[$i], @VN ) ) {
				if ( is_member( $currentProduction[$i], @VN ) ) {  #非终结符
					if ( not exists( $followSets{ $currentProduction[$i] } ) ) {
						my @emptyArray = ();
						$followSets{ $currentProduction[$i] } = \@emptyArray;
					}
					if ( defined( $currentProduction[ $i + 1 ] ) ) {
						if ( is_member( $currentProduction[ $i + 1 ], @VN ) ) {
							$countChanged += mergeArray(
								$followSets{ $currentProduction[$i] },
								$firstSets{ $currentProduction[ $i + 1 ] }
							);
						}
						else {
							$countChanged += mergeArray(
								$followSets{ $currentProduction[$i] },
								[ $currentProduction[ $i + 1 ] ]
							);
						}
					}
				}
			}
		}
		my $j;
		for ( my $i = $len - 1 ; $i > 0 ; $i-- ) {
			for (
				$j = $i ;
				(
					$j > 0 and ( is_member( $currentProduction[$j], @VN ) )
					  and (
						is_member(
							'ε', @{ $firstSets{ $currentProduction[$j] } }
						)
					  )
				  ) ;
				$j--
			  )
			{
				$countChanged += mergeArray(
					$followSets{ $currentProduction[$j] },
					$followSets{ $currentProduction[0] }
				);
			}
		}
		if ( $j > 0 and ( is_member( $currentProduction[$j], @VN ) ) ) {
			$countChanged += mergeArray(
				$followSets{ $currentProduction[$j] },
				$followSets{ $currentProduction[0] }
			);
		}
	}
	return $countChanged;
}
loadGrammar;
for (@Productions) {
	FirstSet( ${$_}[0] );
}
my $changed = FollowSet;
while ( $changed ne 0 ) {
	$changed = FollowSet;
}
$changed = FollowSet;
while ( $changed ne 0 ) {
	$changed = FollowSet;
}
print Dumper( \@Productions, \@VN, \@VT, \%firstSets, \%followSets ) . "\n";
__DATA__
program → block
block → { decls stmts }
decls →  decl decls | ε
decl → type id ;
type →  basic type'
type' →  [ num ] type' | ε
stmts → stmt stmts | ε
stmt → loc = bool ; | if ( bool ) stmt | if ( bool ) stmt else stmt | while ( bool ) stmt |do stmt while ( bool ) ; | break ; |    block
loc →  id loc'
loc' → [ bool ] loc'  | ε
bool  →  join  bool'
bool' →    || join bool'  | ε
join  →  equality join'
join'  →  && equality join' |  ε
equality  →  rel equality'
equality'  →   == rel equality' | != rel equality' |  ε
rel → expr < expr | expr <= expr | expr >= expr | expr > expr | expr 
expr →term expr'
expr' →   + term expr' | - term expr' | ε
term →  unary term'
term' →  * unary term' | / unary term' |  ε
unary → ! unary | - unary | factor
factor→  ( bool ) | loc | num | real | true | false
