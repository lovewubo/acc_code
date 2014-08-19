#!/bin/perl -w

use strict;

my $suffix = "xml";
@ARGV > 0 || die"usage:preprocessing.pl input_file [output_file]\n";

my $str;
my @all;
my $infile = "$ARGV[0]";
my $outfile = "";
if(@ARGV > 1){
	$outfile = "$ARGV[1]";
} else {
	@all = split(/\\|\//, $infile);
	if(@all > 1){
		$outfile = pop(@all);
		$outfile = "new_$outfile";
	} else {
		$outfile = "new_$infile";
	}
}

my @alltxt;
my $xmltitle;
my %xmlinfo;
my %allinfo;

open(INFILE, "<$infile") ||die"can't open file:$infile\n";
open(OUTFILE, ">$outfile") ||die"can't write file:$outfile\n";
@alltxt = <INFILE>;
chomp(@alltxt);
for(my $i=0; $i<@alltxt; $i++)
{
	$str = $alltxt[$i];
	$str =~ s/^\s+//;##去掉行首空格
	$str =~ s/\s+$//;##去掉行尾空格
	if($str ne "")
	{
		if($str =~ /$suffix/){
			my $xmltitle = $str;
			my %xmlinfo = ();

			$i++;
			for(; $i<@alltxt; $i++){
				$str = $alltxt[$i];
				$str =~ s/^\s+//;##去掉行首空格
				$str =~ s/\s+$//;##去掉行尾空格
				if($str =~ /$suffix/)
				{
					$i = $i - 1;
					last;
				}
				
				@all = split(/\s+/, $str);
				if(@all > 1 && $all[1] ne "")
				{
					my $key = shift(@all);
					my $valuestr = join(" ", @all);
					$xmlinfo{$key} = $valuestr;
				}
			}
			my $len = keys %xmlinfo;
			if($len > 0){
				if(exists $allinfo{$xmltitle}){
					die"same xml file happened:$str\n";
					exit(1);
				}
				$allinfo{$xmltitle} = \%xmlinfo;
			}
		}
	}
}

my $statfilecnt = 0;##统计有多少个替换文件
my $statitemcnt = 0;##统计有多少个替换条目
foreach my $key(keys %allinfo){
	print OUTFILE "$key\n";
	$statfilecnt++;
	foreach my $key2(keys %{$allinfo{$key}}){
		print OUTFILE "<$key2> <${$allinfo{$key}}{$key2}>\n";
		$statitemcnt++;
	}
	print OUTFILE "\n";
}
close(INFILE);
close(OUTFILE);

print "统计：需要替换的文件个数是$statfilecnt, 需要替换的条目个数是$statitemcnt\n";
