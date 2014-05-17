mediabreaker
============

To manage media on JBOD. Utils to process DVD/Bluray backups into mkv files, create a logical directory structure of symlinks, schedule overnight wake-ups of the system to do these things, and run in screen so one can check on progress, or interrupt a title running forever without killing the entire batch. Safe to rerun, will skip titles that exist rather than overrite them. Clear out failed files to have the system automatically retry it the next run.

It's not pretty. It encodes all videos the same way, which I'm generally happy with, though I'm considering handling interlaced automatically somehow. here's what the pieces do. Each one might have some configs you need to adjust, and most have some additional comments inside. WARNING THIS WILL RM -RF /videolinks and /musiclinks by default. 

USAGE: 
1. install handbrake and HandBrakeCLI, and set path in 'handbreaker' scripts (default /usr/local/HandBrakeCLI). You might wish to comment out the system call in these scripts for testing at first. 
2. configure sources and destination directories inside makemkv, makelinks and/or backup\* scripts. You can run these manually if you wish.
3. choose components to run inside processvideo, and cron it.

processvideo: sets up a lock file before calling the subscripts, so you can safely cron it (in a screen session if desired) and not worry about multiple encodes happening. Also calls the link and backup scripts. 

makemkvs: wrapper to specify source and destination directories for the handbreaker scripts here. It's good to read and write from separate disks for perf reasons. Configure video options in the handbreaker scripts themselves. 

handbreaker.pl: Looks for VIDEO\_TS folders inside dvd title folders in a source directory, and writes them as plain mkv files in a destination directory. Skips short titles, and appends the title number to all titles but title 1. Grabs all audio streams.

brhandbreaker.pl: Looks for mkv files without parent directories in a source folder, writes compressed mkv files to a destination directory. 

makelinks: configuration wrapper for link scripts. Set up your source and destination directories here, and it will create a sane tree of links for titles across multiple disks. protip: Share the top level folders of these trees via samba, and make them read only. WARNING THIS WILL RM -RF /videolinks and /musiclinks. I need to implement a safer way.

linkmaker: The script that does the work of making links.

backupmp3/backupmkv: scripts to mount your usb drive and copy your files to it...if it successfully mounts. needs some alerting probably. check your backups.

Credit to David Colbert for original handbreaker perl wrappers
