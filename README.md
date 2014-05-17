mediabreaker
============

To manage media on JBOD. Utils to process DVD/Bluray backups into mkv files, create a logical directory structure of symlinks, schedule overnight wake-ups of the system to do these things, and run in screen so one can check on progress, or interrupt a title running forever without killing the entire batch. Safe to rerun, will skip titles that exist rather than overrite them. Clear out failed files to have the system automatically retry it the next run.

It's not pretty. It encodes all videos the same way, which I'm generally happy with, though I'm considering handling interlaced automatically somehow. here's what the pieces do. Each one might have some configs you need to adjust, and most have some additional comments inside. CHECK THE DIRECTORIES IN makelinks BEFORE YOU RM -RF YOUR ENTIRE /videos or /music stash. 

processvideo: sets up a lock file before calling the subscripts, so you can safely cron it (in a screen session if desired) and not worry about multiple encodes happening. Also calls the link and backup scripts. 

makemkvs: wrapper to specify source and destination directories for the handbreaker scripts here. It's good to read and write from separate disks for perf reasons. Configure video options in the handbreaker scripts themselves.

handbreaker.pl: Looks for VIDEO\_TS folders inside dvd title folders in a source directory, and writes them as plain mkv files in a destination directory. Skips small titles, and appends the title number to all titles but title 1. Grabs all audio streams.

brhandbreaker.pl: Looks for mkv files without parent directories in a source folder, writes compressed mkv files to a destination directory. 

makelinks: configuration wrapper for link scripts. Set up your source and destination directories here, and it will create a sane tree of links for titles across multiple disks. 

linkmaker: The script that does the work of making links. 

backupmp3/backupmkv: scripts to mount your usb drive and copy your files to it if it successfully mounts. needs some alerting probably. 
