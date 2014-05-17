mediabreaker
============

To manage home media on Linux+JBOD. Utils to:  

* Process DVD/Bluray backups into mkv files.
* Create an easy to browse directory structure of symlinks for your content scattered across "Just a Bunch Of Disks".
* Schedule overnight wake-ups of the system to do these things. 
* Run in screen so one can check on progress, or interrupt a title running forever without killing the entire batch. 
* Safe to rerun, will skip titles that exist rather than overrite them. 
* Clear out failed files to have the system automatically retry it the next run.

The system encodes all dvd's same way (blurays are a higher quality), which I'm generally happy with. I get down to 20-40% of the original MPEG2 size for DVDs. 'Raw' DVD isn't that sharp when you look closely, but for most content I have a hard time telling the difference between raw and re-encoded. You'd have to clone the perl script to have different sets of video options, like quality level or deinterlacing.

I don't like messing with consumer grade raid, but I do like having my dvd and bluray collections online so we can play them from anywhere. Use multiple harddrives to your advantage for ripping and encoding performance (I have two DVD readers in my PC, so I can rip DVDs over samba to two hard drives in the server, then re-encode video from one to the other). I stash compressed video on multiple older small drives, and back up to a USB enclosure with my newest and largest.

# USAGE

1. Install handbrake and HandBrakeCLI, and set path in 'handbreaker' scripts (default /usr/local/HandBrakeCLI). You might wish to comment out the system call in these scripts for testing at first. 
2. Configure sources and destination directories inside makemkv, makelinks and/or backup\* scripts. You can run these manually if you wish.
3. Choose components to run inside processvideo, and cron it.
4. Occasionally check on your progress, and clean out the raw video from your source folders when you are satisfied. (I'm lazy and just look quickly for any 'runty' looking filesizes).

Here's what the pieces do. Each one might have some configs you need to adjust, and most have some additional comments inside. WARNING THIS WILL RM -RF /videolinks and /musiclinks by default. 

**processvideo:** sets up a lock file before calling the subscripts, so you can safely cron it (in a screen session if desired) and not worry about multiple encodes happening. Also calls the link and backup scripts. 

**makemkvs:** wrapper to specify source and destination directories for the handbreaker scripts here. It's good to read and write from separate disks for perf reasons. Configure video options in the handbreaker scripts themselves. 

**handbreaker.pl:** Looks for VIDEO\_TS folders inside dvd title folders in a source directory, and writes them as plain mkv files in a destination directory. Skips short titles, and appends the title number to all titles but title 1. Grabs all audio streams.

**brhandbreaker.pl:** Looks for mkv files without parent directories in a source folder, writes compressed mkv files to a destination directory. 

**makelinks:** configuration wrapper for link scripts. Set up your source and destination directories here, and it will create a sane tree of links for titles across multiple disks. protip: Share the top level folders of these trees via samba (enable follow symlinks), and make them read only. WARNING THIS SCRIPT WILL RM -RF /videolinks and /musiclinks. I need to implement a safer way.

**linkmaker:** The script that does the work of making links.

**backupmp3/backupmkv:** scripts to mount your usb drive and copy your files to it...if it successfully mounts. needs some alerting probably. check your backups.

Credit to David Colbert for original handbreaker perl wrappers
