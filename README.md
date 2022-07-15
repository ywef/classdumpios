class-dump-c
==========

This project is an amalgam of a few different versions of classdump. Initially based on a version by [DreamDevLost](https://github.com/DreamDevLost/classdumpios)
who made his as an iOS port from [nygard/class-dump](https://github.com/nygard/class-dump). From there I have manually merged in bits and pieces from various PR's against the original 
[ie #78](https://github.com/nygard/class-dump/pull/78) and then made a working macOS version again.

In iOS 13 Apple introduced some new load commands into DYLD (specifically `LC_DYLD_CHAINED_FIXUPS` and `LC_DYLD_EXPORTS_TRIE`) But didn't start widely using them
until iOS 15, once binaries are built with `-fixup_chains` any class-dump projects that relied on the old methodolgy would no longer work. [This writeup and related code](https://github.com/qyang-nj/llios/blob/main/dynamic_linking/chained_fixups.md) was instrumental in me understanding how to implement this newer methodology.

Ill do a more extended write-up of everything involved in getting this working again, to help remember, but also to help educate anyone else curious about these innerworkings.

Special thanks to: 

- [Steve Nygard](https://github.com/nygard/) for the original class-dump
- [DreamDevLost](https://github.com/DreamDevLost/classdumpios) for his iOS port
- [Derek Selander](https://github.com/DerekSelander) for this amazing [writeup](https://derekselander.github.io/dsdump/)
- [Qing Yang](https://github.com/qyang-nj) For his [llios](https://github.com/qyang-nj/llios/) repo and related writeups
- [Noah Martin](https://www.emergetools.com/blog/posts/iOS15LaunchTime) For the linked writeup on `LC_DYLD_CHAINED_FIXUPS`

**NOTE: For a little while I kept the master and macOS branches in sync, but they have since fallen way out of sync, once I finish tidying this up I'll pull them back in sync so the iOS version will have parity with the macOS version.**


