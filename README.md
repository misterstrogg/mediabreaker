mediabreaker
============

To manage home media on a Linux server. Features:  

* Re-encode DVD/Bluray backups into smaller mkv files of comparable quality.
* Create an easy to browse directory structure of symlinks for your content scattered across "Just a Bunch Of Disks".
* Schedule overnight wake-ups of the system to do these things, and sleep again when done. 
* Run in screen so one can check on progress, or interrupt a title running forever without killing the entire batch. 
* Safe to rerun, will skip titles that exist rather than overrite them. 

Things left for you to do:
* Rip your DVD collection with something like DVDShrink, in VIDEO\_TS/VOB folders, without recompressing.
* Rip your BluRay collection with something like MakeMKV, into uncompressed mkv files. 
* Setup Suspend and Wake-On-Lan so you can wake your server on demand when you want to watch your content.
* Clear out failed files to have the system automatically retry it the next run.


The perl scripts contain the video encode options (blurays are a higher quality), which I'm generally happy with. I get down to 20-40% of the original MPEG2 size for DVDs. DVD isn't that sharp when you look closely (especially nowadays, they want you to buy bluray), so neither is the output, but for most content I have a hard time telling the difference between DVD MPEG2 and the re-encoded MPEG4. You'd have to clone the perl script to have different sets of video options, like quality level or deinterlacing. 

I like having my dvd and bluray collections online so I can play them from anywhere, but consumer grade RAID is just too sketchy (lose your card or Motherboard, good luck finding one that can access your existing data. Need to have lots of same-size same-speed drives. Rebuilds from drive failures tend to fail alot as well). It's much more cost effective to just buy new hard drives one at a time (every year they get bigger and cheaper), and just set up your own backup/redundancy. 

I use multiple harddrives to my advantage for ripping and encoding performance (I have two DVD readers in my windows gaming PC, so I can rip DVDs over samba to two hard drives in the server in parallel, then re-encode video from one to the other). I stash compressed video on multiple older smaller drives (and generate symlinks to make it look contigous), then I back up to a USB enclosure with my newest and largest drive. 

I use a few xmbc front ends, which wake up the server when they wake up (there's a WOL function in xbmc). My back-end is xbmcbuntu as well. The processed output is also a reasonable size for keeping a few favorites on your smartphone.

# SETUP

1. Rip your DVDs and BluRays to the source folders. 
2. Install handbrake and HandBrakeCLI (www.handbrake.fr), and set path in the 'handbreaker' perl scripts (default /usr/local/HandBrakeCLI). You might wish to comment out the system call in these scripts for testing at first. 
3. Configure sources and destination directories inside makemkv, makelinks and/or backup\* scripts. You can run these manually if you wish.
4. Choose components to run and a wake-up time inside processvideo, and cron it to run a minute or so after the machine's scheduled wake-up (ideally at a time when you are NOT likely to be watching video).

# UPKEEP

Occasionally check on your progress. Clean out the raw video from your source folders when you are satisfied, and clean up any extras or redundant 'titles'. I'm lazy and just look quickly for any 'runty' looking filesizes, then I mv everything in the source folder to a 'processedDVD' folder that I can empty when i really need to. I usually only rip the main movie and ignore the trailers and behind the scenes stuff, but the scripts do work with fulldisc rips. For those, I move all files with 'title#' appended into an 'extras' folder and delete any unwanted cuts of the movie, leaving only the main movie in the movies folder. If you wanted to keep all the extras with the movie, you could modify the perl scripts quite easily to create a parent folder (some frontends actually want this).

Here's what the pieces do. Each one might have some configs you need to adjust, and most have some additional comments inside. WARNING THIS WILL RM -RF /videolinks and /musiclinks by default. 

**processvideo:** sets up a lock file before calling the subscripts, so you can safely cron it (in a screen session if desired) and not worry about multiple encodes happening. Also calls the link and backup scripts. Sets the machine to wake up (default at midnight) and suspends it when done.

**makemkvs:** wrapper to specify source and destination directories for the handbreaker scripts here. It's good to read and write from separate disks for perf reasons, but not strictly required. Configure video options in the handbreaker scripts themselves. 

**handbreaker.pl:** Looks for VIDEO\_TS folders inside dvd title folders in a source directory, and writes mkv files in a destination directory. Skips short titles, and appends the title number to all titles but title 1. Grabs all audio streams (they are small relative to the video, but consider not ripping the ones you dont want).

**brhandbreaker.pl:** Looks for mkv files without parent directories in a source folder, writes compressed mkv files to a destination directory. 

**makelinks:** configuration wrapper for link script. Set up your source and destination directories here, and it will create a tree of links for titles across multiple disks. protip: Share the destination directories via samba (enable follow symlinks), or point your local plex install here. WARNING THIS SCRIPT WILL RM -RF /videolinks and /musiclinks. (I probably need to implement a safer way.)

**linkmaker:** The script that does the work of making links.

**backupmp3/backupmkv:** scripts to mount your usb drive and copy your files to it...if it successfully mounts. needs some alerting probably. check your backups occasionally.

Credit to David Colbert for original handbreaker perl wrappers.
