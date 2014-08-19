#!/bin/perl -w

use strict;
use File::Path;

my $suffix = "xml";
@ARGV > 1 || die"usage:convert.pl conv_list inputdir [outputdir]\n";

my $str;
my @all;
my $list = "$ARGV[0]";#输入的替换列表文件
my $inDir = "$ARGV[1]";#替换文件所在的目录
my $outDir = "";
if(@ARGV > 2){
	$outDir = "$ARGV[2]";
} else {
	@all = split(/\\|\//, $inDir);
	if(@all > 1){
		my $dirname = pop(@all);
		$outDir = join("\\", @all);
		$outDir = "$outDir\\new_$dirname";#生成新的替换文件的存储目录
	} else {
		$outDir = "new_$inDir";
	}
}

if(!-d $outDir){
	mkpath($outDir) || die"can't create new dir:$outDir\n";
}

my @alltxt;
my $xmltitle;
my %xmlinfo;
my %allinfo;

open(INFILE, "<$list") || die"can't open list file:$list\n";
@alltxt = <INFILE>;
chomp(@alltxt);
close(INFILE);

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
				
				if($str =~ /<(.*)>\s+<(.*)>/)
				{
					my $key = $1;
					my $valuestr = $2;
					if($key =~ /^<(.*)>$/){
						$key = $1;
					}
					if($valuestr =~ /^<(.*)>$/){
						$valuestr = $1;
					}
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

my @unconvitem;##统计有多少条目没有被替换过
my @multiconvitem;##多次被替换过的条目

foreach my $key(keys %allinfo){
	undef @alltxt;##清空数组
	if(open(IN, "<$inDir\\$key")) {
		@alltxt = <IN>;
		close(IN);
	}elsif(open(IN, "<$key")) {
		@alltxt = <IN>;
		close(IN);
	}else{
		warn"warning: can't open file:$key\n";
		next;
	}
	
	##剥离目录
	@all = split(/\\|\//, $key);
	pop(@all);
	if(@all > 0){
		my $temp_outdir1 = join("\\", @all);
		my $temp_outdir2 = "$outDir\\$temp_outdir1";
		if(!-d $temp_outdir2){
			mkpath($temp_outdir2) || die"can't make directory:$temp_outdir2\n";
		}
	}

	$statfilecnt++;
	open(OUT, ">$outDir\\$key") || die"can't create file:$outDir\\$key\n";
	
	my %conv_indicator;##用来指示哪些条目一次都没有被替换过
	foreach my $key2(keys %{$allinfo{$key}}){
		$conv_indicator{$key2} = 0;
	}
	
	#my $count = keys %{$allinfo{$key}}; 
	#print "$key ";
	#print "$count\n";die;
	
	if(@alltxt > 0){
		
		##遍历文件
		for(my $i=0; $i<@alltxt; $i++){
			$str = $alltxt[$i];
			if($str =~ /<(.*)>(.*)<\/(.*)>/){
				my $secstr = $2;##中间的字段部分
				
				##遍历hash
				foreach my $key3(keys %{$allinfo{$key}}){
					if($secstr =~ /$key3/){
						my $newval = ${$allinfo{$key}}{$key3};
						$str =~ s/$key3/$key3\;$newval/;
						
						$statitemcnt++;
						$conv_indicator{$key3}++;
						last;
					}
				}
			}
			print OUT "$str";
		}
	}
	close(OUT);
	
	foreach my $key4(keys %{$allinfo{$key}}){
		if($conv_indicator{$key4} == 0){
			##仍然为0，说明这个条目还没有被替换过
			my $itemstr = "$key: $key4";
			push(@unconvitem, $itemstr);
		} elsif ($conv_indicator{$key4} > 1) {
			##大于1，说明这个条目被多次替换过
			my $itemstr = "$key: $key4";
			push(@multiconvitem, $itemstr);			
		}
	}
}

print "统计：实际替换的文件个数是$statfilecnt, 实际替换的条目个数是$statitemcnt\n";

my $writetofile = 1;##将没有找到的条目输出到文件中
if(@unconvitem > 0){
	print "warning: 发现列表中有些条目没有被替换过，请检查";
	if($writetofile == 1){
	print "文件：unfinditem.txt\n";
	open(STATFILE, ">unfinditem.txt")||die;
	print STATFILE "以下条目在文件中未找到：\n";
	for(my $i=0; $i<@unconvitem; $i++){
		print STATFILE "$unconvitem[$i]\n";
	}
	close(STATFILE);
	} else {
		print "\n";
		##将没有找到的条目显示在屏幕上
		print "以下条目在文件中未找到：\n";
		for(my $i=0; $i<@unconvitem; $i++){
			print "$unconvitem[$i]\n";
		}
	}
}

if(@multiconvitem > 0){
	print "\nwarning: 发现列表中有些条目被多次替换，请检查";
	if($writetofile == 1){
	print "文件：multifinditem.txt\n";
	open(STATFILE2, ">multifinditem.txt")||die;
	print STATFILE2 "以下条目在文件中被多次替换：\n";
	for(my $i=0; $i<@multiconvitem; $i++){
		print STATFILE2 "$multiconvitem[$i]\n";
	}
	close(STATFILE2);
	} else {
		print "\n";
		##将多次替换的条目显示在屏幕上
		print "以下条目在文件被多次替换：\n";
		for(my $i=0; $i<@multiconvitem; $i++){
			print "$multiconvitem[$i]\n";
		}
	}
}
