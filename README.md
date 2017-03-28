# The kitchen is so dirty, clean it up!

Filthy Kitchen is a homebrew NES game, written in 6502 assembly. You control the hapless kitchen owner, who needs to find the broom, picking up unspoiled food along the way. Avoid anything dirty if you want to succeed. Kill flies using your boomerang-like swatter; if you kill multiple flies without catching it, you'll get a high scoring combo!

# Dependencies

* [ca65](http://cc65.github.io/cc65/)

* make

* python

* [makechr](http://github.com/dustmop/makechr)

* [famitracker](http://www.famitracker.com/)

* [famitone2](https://shiru.untergrund.net/code.shtml)

* OSX only: [wine](https://www.davidbaumgold.com/tutorials/wine-mac/)

# Building

* Install the dependencies

* Make sure ca65, make, makechr, and python are in your PATH as well.

* Modify your PATH so it includes Famitracker.exe and the utilities from famitone2: nsf2data.exe and ftm2data.exe. Alternatively, copy those executables to a folder that your PATH already points to.

* For OSX builds using wine, create scripts that call these exe's using wine, and put those in your PATH.

* For example:

```
wine famitracker.exe "$@"
```
in a file called "famitracker" in your PATH. Make sure the executable bit is set:
```
chmod a+x famitracker
```

# Make

Once ready, call make to build:
```
make
```

# Secret password

You've found a secret at the end of the README. Tell the title screen why the kitchen needs to be clean. Say "dirt bad" (D-U-R-D-B-A-D).

