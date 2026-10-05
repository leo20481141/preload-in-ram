# Preload In RAM
Preload apps and files to ram so when you open them, they are ready to use inmediately.
This not only allows you to preload apps to RAM but to also copy entire folders to RAM. This makes a significant difference in some app's performance.
The changes made to folders copied to RAM are restored to disk upon shutdown.

Steps to preload an app to RAM:
- create the "services" folder.
- Create a file with a name that doesn't colide with any service, the filename is going to be used as the service name.
- Create a file with the following arrays:
  - For copying something to RAM, you need the variables DISKDIRS, RAMDIRS and BACKUPDIRS.
  - For preloading something, you need the variable PRELOAD_DIRS.
- Keep in mind that the service files are just copy-pasted into a bash script, so bash code is also valid.

How it works:
- At boot time, the specified folders are loaded into RAM.
- At shutdown, if the folders have been copied rather than just preloaded, the changes made to the foders in RAM are copied back to disk.

You can find examples of apps copied to RAM in the examples directory.
