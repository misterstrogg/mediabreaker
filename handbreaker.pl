#!/usr/bin/perl -w
# Finds all VIDEO_TS folders inside input folder and individually
# process all titles found. Please note: this script may run for
# weeks if you have a slow computer and/or a lot of VIDEO_TS 
# folders to process.
#
# David Colbert
# Sun Apr  8 18:06:57 EDT 2007
#
# Thu Jun  7 20:29:33 EDT 2007
# Renamed from mediaforker.pl to handbraker.pl to match handbrake's 
# schizophrenic project name. Also, now defaults to HandBrakeCLI, 
# but falls back to MediaForkCLI. 
#
# Fri Jan 25 15:20:27 EST 2008
# Updated for the latest HandBrakeCLI, removed switches that are 
# already in defaults. Added deintelacing back in, since HandBrake 
# now has better deinterlacing. Removed all references to mediafork.
#
# Sat Jan 31 16:34:52 EST 2009
# Updated for handbrake 0.9.3, changed defaults to virtually the 
# same as quicktime, added in new title scanner regexp, added time threshold
# so that only long titles (greater than 10 mins) are processed.
# TODO: Switch to GetOpt::Long for arg handling, but it should keep 
# pass-through HandBrakeCLI switch functionality

#STROGG
# Oct 2011
# Added code for ALL audio and subtitle tracks. 
# Title 1 gets the default name, Title <> 1 gets the title appended. 
# Encoding is skipped if output exists. (Allows cron and cancel/rerun, just remember to manually remove any unfinished output.) 

#use strict;
use File::Find ();
# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

# Declare subroutine for File::Find
sub wanted;

#
# Process input args
#
my $narg = scalar( @ARGV );

#
# Default Quality Settings (virtually identical to --preset QuickTime)
# Comment out any settings that you don't want
#

my $compressargs = ""; # Do not comment this out
# Video

#$compressargs = $compressargs . ' --preset="Normal"';   # Video format
$compressargs = $compressargs . " -f mkv -e x264";   # Video format
$compressargs = $compressargs . " -b ";         # Video bitrate (atv=2500,iphone=1000)
#$compressargs = $compressargs . " -d";               # Deintelacing
$compressargs = $compressargs . " -m";               # Chapter Markers
#$compressargs = $compressargs . " -2 -T";            # 2-pass turbo
$compressargs = $compressargs . " --strict-anamorphic";               # Anamorphic

# Advanced x264 options
#$compressargs = $compressargs . " -x ref=3:mixed-refs:bframes=3:weightb:direct=auto:me=umh:subme=7:analyse=all:8x8dct:trellis=1:no-fast-pskip=1:psy-rd=1,1";

# Audio
$compressargs = $compressargs . " -E copy";         # Audio format
#$compressargs = $compressargs . " -E ac3";         # Audio format

#$compressargs = $compressargs . " -B 384";         # Audio bitrate (384=64x6 for 5.1)
$compressargs = $compressargs . " -R auto";         # Audio sample rate
#$compressargs = $compressargs . " -a 1";            # Audio Track
$compressargs = $compressargs . " -6 dpl2";         # Audio Mixdown

#$compressargs = $compressargs . " --subtitle-forced -N eng";         # Subtitles


my $allargs = "";
my $infolder = "";
my $outfolder = "";
my $ext = ".mkv"; 

my $helpstr = "\nhandbraker.pl <infolder> <outfolder> <args>\n\
This script will recursively process all titles longer than 10 minutes in all VIDEO_TS folders inside \
<infolder>. <infolder> is required. \n\
<outfolder> is optional. If specified, this is where the movie files will be \
placed. If not specified, files will be placed at same level \
as the DVD folder that contains the VIDEO_TS folder. \n\
<args> are optional. If you choose to set args, you must also set <outfolder> \
Defaults: Pretty much the same as '--preset QuickTime', with minor tweaks. \n\
Examples:\n# Put MP4s right next to backups:\nprompt% handbraker.pl /Volumes/MyDVDs\n\
# Put MP4s in your Movies folder:\nprompt% handbraker.pl /Volumes/MyDVDs ~/Movies\n\
# Put AVIs into your movies folder:\nprompt% handbraker.pl /Volumes/MyDVDs ~/Movies -f avi ...\n\
# View the help:\nprompt% handbraker.pl --help\n\
Notes:\nHandbrake has a unique interpretation for \"quality\". I recommend that you read \
up on how it works before attempting the \"-q\" switch. Also, Handbrake will undoubtedly \
eventually make large scale processing easier, making this wrapper unnecessary.\n\
Use \"HandBrakeCLI --help\" to find out how to set your own compression args.\n\n";

if( $narg == 0 )
{
   die $helpstr;
}
elsif( $narg == 1 )
{
   $infolder = $ARGV[0];
   $allargs = $allargs . " $ARGV[0]";
}
elsif( $narg == 2 )
{
   $infolder = $ARGV[0];
   $outfolder = $ARGV[1];
   $allargs = $allargs . " $ARGV[0] $ARGV[1]";
}
elsif( $narg > 2 )
{
   # More switches used than just folder, so build up user-specified args from inputs
   $infolder = $ARGV[0];
   $outfolder = $ARGV[1];
   $allargs = $allargs . " $ARGV[0] $ARGV[1]";
   $compressargs = "";
   for( my $thisArg=2; $thisArg < $narg; $thisArg++ )
   {
      $compressargs = $compressargs . " $ARGV[$thisArg]";
      $allargs = $allargs . " $ARGV[$thisArg]";
   }
}

# Spit out some help if asked
die $helpstr if( $allargs =~ /(-h|-help|--help|--h)/ );

# Set filename extension for output movies
if( $compressargs =~ /avi/ )
{ $ext = ".avi"; }
elsif( $compressargs =~ /ogm/ )
{ $ext = ".ogm"; }
elsif( $compressargs =~ /mp4/ )
{ $ext = ".mp4"; }
elsif( $compressargs =~ /mkv/ )
{ $ext = ".mkv"; }


#
# Find HandBrakeCLI
#
my $HandBrakeCLI = "/usr/bin/HandBrakeCLI";
my $HandBrakeMissing = "No HandBrakeCLI found in /usr/local/bin\n\
Please download HandBrakeCLI and place it in /usr/local/bin\n";
die $HandBrakeMissing if( !(-x $HandBrakeCLI ) );

#
# Find VIDEO_TS folders
#
my @allvidts = ();
# Traverse $infolder, push VIDEO_TS folders into allvidts
File::Find::find({wanted => \&wanted}, $infolder);
die "No VIDEO_TS folders found in $infolder\n" if( @allvidts == 0 );

#
# Processing loop
#

# Scan for all titles
my @hbcmds = ();
my $timeThreshold = 4*60; # Set a 10 minute time threshold to skip ads, trailers
foreach my $vidts (@allvidts)
{

   my @titles = ();
   my @durations = ();
   my @audiotracks = ();
   my @subtitletracks = ();
my $subtitlesection = "no";
my $audiosection = "no";
my $a = 0;
my $s = 0;
my $titnumprev= 1;
   #  Find all titles in this video_ts 
   print "$HandBrakeCLI -i \"$vidts\" -t 0 2>&1";
   open( SCANNER, "$HandBrakeCLI -i \"$vidts\" -t 0 2>&1 |" );
   while( <SCANNER> )
   {
      chomp();

     	if( $_ =~ /(\s*\+\s+title\s+)(\d+)(:)*/ ) {
	$titnum = $2;  
    push( @titles, $titnum);
	
	if ($titnumprev =~ /$titnum/) {
	} else {
	$titnumprev = $titnum;
	$a = 0;
	$s = 0;
	}
	$titnum = $titnum;


	}
      push( @durations, (($2*3600)+($3*60)+$4) ) if( $_ =~ /(\s*\+\s*duration\s*\:)\s*(\d+):(\d+):(\d+)*/ );

	if ( $subtitlesection =~ /yes/ ) {
		if (( $_ =~ /Eng/ ) || ( $_ =~ /eng/ )) {
		$s++;
		 push ( @subtitletracks , $titnum."Z".$s );
		} else {
		$subtitlesection = "no";
		}
	}
	
	if ($audiosection =~ /yes/) {	
		if ( $_ =~ /subtitle tracks/ ) {
		$audiosection = "no";
		$subtitlesection = "yes";
		} else {
		 $a++;
		push ( @audiotracks , $titnum."Z".$a );
		}
	}
	if ( $_ =~ /audio tracks/ ) {
	# Begin Audio Tracks
	$audiosection = "yes";
	}
   }
   close( SCANNER );



   # Set output file and output folder
   my $iTitle = 0;
   foreach my $title (@titles) 

   {
	my @audioargsarr = ();
	my @subtitleargsarr = ();
	my $audioargs = "";
	my $subtitleargs = "";

	foreach (@audiotracks) {
		@atsplit = split(/Z/, $_);
		if ( $atsplit[0] =~ /$title/) {
		push ( @audioargsarr , $atsplit[1] );
		} 
	}
	@atsplit = -1;
	foreach (@subtitletracks) {
		@stsplit = split(/Z/, $_);
		if ( $stsplit[0] =~ /$title/) {
		push ( @subtitleargsarr , $stsplit[1] );
		}
	}
	my $audioargs = join(',', @audioargsarr);
	my $subtitleargs = join(',', @subtitleargsarr);

      if( $durations[$iTitle] > $timeThreshold )
      {
         my $outfile = "";
         if( $outfolder eq "" )
         {
            my @ts_split = split( /\/VIDEO_TS/, $vidts );
		if ($title =~ /1/) {
            $outfile = $ts_split[0] . "$ext";
		} else {
            $outfile = $ts_split[0] . ".title$title$ext";
		}
         }
         else
         {
            my @slash_split = split( /\//, $vidts );
		if ($title < 2) {
            $outfile = $outfolder . "\/" . $slash_split[-2] . "$ext";
        	} else {    
	$outfile = $outfolder . "\/" . $slash_split[-2] . ".title$title$ext";
		}
         }
	print $outfile."\n";
	my @outsplit = split( /\//, $outfile );
        # build system call strings
	if (-e $outfile) {
         print "$outfile exists! skipping\n";
	} else {
         print "Will Create $outfile\n";
         push( @hbcmds, ( "$HandBrakeCLI -i \"$vidts\" -o \"$outfile\" -t $title $compressargs -s $subtitleargs -a $audioargs 2> \"/var/log/handbrake/$outsplit[3].$title.log\"" ) );
	}
      }
      $iTitle++;

	@audioargsarr = -1;
   }


}


# Execution
foreach my $hbcmd (@hbcmds)
{
   system( $hbcmd );
   print( $hbcmd."\n" );

}

#
# Subroutines
#

sub wanted {
    my ($dev,$ino,$mode,$nlink,$uid,$gid);

    /^VIDEO_TS\z/s &&
    (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
    -d _ &&
   push( @allvidts, $name);
}
