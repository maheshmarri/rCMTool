#!/usr/bin/perl

use strict;
use File::Copy;
use Cwd;
use File::Spec::Functions;
use Getopt::Std;
use Sys::Hostname;
use File::Basename;



print <<EOF;



************************************************
This is a rudimentariy coonfiguration management 
tool for production services with a simple php application
************************************************


EOF



$ENV{'DEBIAN_FRONTEND'}="noninteractive";
my $platform = `lsb_release  -i`;
$platform =~ s/\n//;


print "Its a $platform  Platform \n";

my $scriptLoc=$0;
my $baseDir=getcwd;
$baseDir=~s/bin//;
my $configLocation=File::Spec->catfile($baseDir,"config");
my $templateLocation=File::Spec->catfile($baseDir,"templates");
my $dependLocation=File::Spec->catfile($baseDir,"dependencies");
my $filesLocation=File::Spec->catfile($baseDir,"files");
my $packagesLocation=File::Spec->catfile($baseDir,"packages");

my $restart=0;
print "Location of the script $baseDir";
my %hashconfig=hashFuntion("$configLocation/config.properties");
exuecuteDepend();
uninstallPackages();
installPackges();
copyFilesRequested();
($restart) and restart();
templates();
checkAppRunning();

exit 1;

sub restart {
	my $output=`needrestart `;
	print "restart output - $output \n";
	
}

sub copyFilesRequested {

	#Run only if install packages for apache specified
	if (-s "$packagesLocation/install.lst") {
			print "Copy Files that are configured \n";
			(! -d $hashconfig{'fileLocation'}) and `mkdir -p $hashconfig{'fileLocation'}`;
			print "$hashconfig{'fileLocation'}/index.html \n";
			(-e "$hashconfig{'fileLocation'}/index.html") and unlink ("$hashconfig{'fileLocation'}/index.html");
			`cp "$filesLocation/index.php" "$hashconfig{'fileLocation'}/index.php"`;
			`chown $hashconfig{'user'}:$hashconfig{'group'}  "$hashconfig{'fileLocation'}/index.php" `;
		
	}
}

sub uninstallPackages {

	#check for Uninstall file with content 
		if (-s "$packagesLocation/uninstall.lst") {
		print "\n Un-Installing Packages from - $packagesLocation/uninstall.lst ";
		open(UNINSTALL,"<$packagesLocation/uninstall.lst") or die "Unable to find open the uninstall list \n";
		foreach(<UNINSTALL>) {
			next if $_=~ /^\n/;
			$_=~ s/^\s+//;
			$_=~ s/\s+$//;
			print "\n checking package is installed - dpkg -l|grep  $_ \n";
			`sudo dpkg -l|grep -i $_`;
			if (! $?) {
				print "\n Removing the package $_\n";
				my $command1=`sudo apt-get remove -y $_`;
				print "\n $command1 \n";
				($command1 =~ /"error|failed"/) or print "\n done ... \n";
				my $command2=`sudo apt-get autoremove -y `;
				print "\n $command2 \n";
				($command2 =~ /"error|failed"/) or print "\n done ... \n";
				my $command3=`sudo apt-get purge -y \$\(dpkg --list |grep '^rc' |awk '{print \$2}'\)`;
				print "\n $command3 \n";
				($command3 =~ /"error|failed"/) or print "\n done ... \n";
				my $command4=`sudo apt-get clean`;
				print "\n $command4 \n";
				($command4 =~ /"error|failed"/) or print "\n done ... \n";
				#($captureOutput =~ /"error|failed"/i) and die "failed to remove the package\n";
			} else {
				print "\n $_  - has already been removed";
			}
		}
	} else {
		print "\n Uninstall list is empty.. ";

	}

}

sub installPackges {
		#check for install file with content 
		
		#check if restart required for the packages installed 
		
		if (-s "$packagesLocation/install.lst") {
			print "\n Installing Packages from - $packagesLocation/install.lst ";
			open(INSTALL,"< $packagesLocation/install.lst") or die "Unable to find open the install list \n";
			foreach  (<INSTALL>) {
				#next if $_=~ /\n/;
				$_=~ s/^\s+//;
				$_=~ s/\s+$//;
				print "\n checking package is installed - dpkg -l|grep  $_ \n";
				`sudo dpkg -l|grep  $_`;
				if ($?) {
					print "Installing package $_ \n";
					my $command5 = `sudo DEBIAN_FRONTEND=noninteractive apt-get install -y  --force-yes $_`;
					print "\n $command5 \n";
					$restart=1;
					($command5 =~ /"error|failed"/i) or print "\n done ... \n ";
				} else {
					print "\n $_ - Packages are Up-to-Date";
				}


			}

		} else {
			print "\n Install List is empty ... \n";
		}
}

sub hashFuntion {
	my ($file) =@_;
	my %hashconfigl;
	open(FILE,"< $file") or die "can not open file ".$!;
	foreach(<FILE>) {
		next if ($_=~ /^#/) ;
		my ($key,$value)=split "=";
		$key =~ s/^\s//;
		$key =~ s/\s$//;
		$value =~ s/^\s//;
		$value =~ s/\s$//;
		$value =~ s/\n//;
		#print "Key - $key \n";
		#print "Value - $value \n";
		$hashconfigl{$key}=$value;
	}
	
	return %hashconfigl;
}

sub exuecuteDepend {
	my $runtimeoutPut;
	print "\n Installing any dependencies mentioned in dependency.sh ...\n";
	print "$dependLocation/dependency.sh \n";
	
	if (-e ".dependency.sh") {
			print "dependency.sh already executed ...if needed to execute remove the file .dependency.sh"
	} else {
		$runtimeoutPut=`bash $dependLocation/dependency.sh`;
		`echo dependency.sh >>.dependency.sh`;
		print "OutPut of the Dependencies execution -  $runtimeoutPut \n";
	}
	
	
}

sub checkAppRunning {

	my $hostname=`hostname`;
	my $appoutout = `curl -sv http://$hostname`;
	print $appoutout;
}

sub templates {
	 my @templates = glob("$templateLocation/*.template");
	 print "\n \n Processing templates - @templates \n \n";
	 (! -d $hashconfig{'templateLocation'}) and `mkdir -p $hashconfig{'templateLocation'}`;
	 my @newlines;
	 foreach my $eachtem (@templates) {
		my $templatename = basename($eachtem);
		my $temp="$hashconfig{'templateLocation'}/$templatename"."temp";
		#print $templatename."\n";
		open(FILE,"<$eachtem") or die "$!";
		open(WRITE,">$temp") or die "$!";
		my @lines = <FILE>;
		my @newlines;
		#print "@lines";
		foreach my $line(@lines) {
			#print "$line \n";
			foreach my $key (sort keys %hashconfig) {
						#print "$key = $hashconfig{$key} \n";
						if ($line =~ /"\#$key\#"/g){
							#print "Find /Replace \n";
							#print "$key = $hashconfig{$key} \n";
							
							$line =~s/"\#$key\#"/$hashconfig{$key}/g;
							#print "line - $line \n";
							#push @newlines,$line;	
						}
				}
				push @newlines,$line;	
				}
				
			#print "@newlines \n";	
			print WRITE @newlines;
			close(FILE);
			close(WRITE);
			`mv $temp $hashconfig{'templateLocation'}/$templatename`;
				
	 }
	
		
}
