class-dump-c
==========

# Background

This project is an amalgam of a few different versions of classdump. Initially based on a version by [DreamDevLost](https://github.com/DreamDevLost/classdumpios)
who made his as an iOS port from [nygard/class-dump](https://github.com/nygard/class-dump). From there I have manually merged in bits and pieces from various PR's against the original 
[ie #78](https://github.com/nygard/class-dump/pull/78) and then made a working macOS version again.

# Chained Fixups

In iOS 13 Apple introduced some new load commands into dyld (specifically `LC_DYLD_CHAINED_FIXUPS` and `LC_DYLD_EXPORTS_TRIE`) But didn't start widely using them
until iOS 15, once binaries are built with `-fixup_chains` any class-dump projects that relied on the old methodolgy would no longer work. [This writeup and related code](https://github.com/qyang-nj/llios/blob/main/dynamic_linking/chained_fixups.md) was instrumental in me understanding how to implement this newer methodology.

I used the macho parser as inspiration for a lot of the chained fixup code while merging it with a new load command class that was based on

# Nitty gritty

My only prior experience with working on class dump was the cleanup work I did in classdump-dyld, I didn't really fully understand the process or how dyld and mach-o files fundamentally worked, and in getting this project updated and working I have a much better understanding. I can't overstate how much value I found in the resources gathered at [this repo](https://github.com/qyang-nj/llios) granted the open source apple code is available elsewhere for otools (cctools) et al, it's nice to have a central place of reference. 

I used`CDLCDyldInfo` as a template for the `CDLCChainedFixups` that does most of the heavy lifting for the newer process. It walks the fixup chains and stores the binds and the rebases in two separate dictionaries, which are subsequently referenced as applicable. The biggest 'gotchas' of this process were the need byte swap and/or bitshift in random circumstances for inexplicable reasons. The samples I modified from llios's macho-parser section (included in this repo in the `samples` folder) were instrumental in figuring this process out. Using some of the undocumented flags I added (-v,-d,-F,-z,-x etc..) On these sample files can give a better understanding on what im talking about, and the journey to figure all of this stuff out. The other big piece of the puzzle was making the adjustments for the differing `DYLD_CHAINED_PTR_64_OFFSET` vs `DYLD_CHAINED_PTR_64` pointer_format's when rebinding & rebasing.

More later...

Special thanks to: 

- [Steve Nygard](https://github.com/nygard/) for the original class-dump
- [DreamDevLost](https://github.com/DreamDevLost/classdumpios) for his iOS port
- [Derek Selander](https://github.com/DerekSelander) for this amazing [writeup](https://derekselander.github.io/dsdump/)
- [Qing Yang](https://github.com/qyang-nj) For his [llios](https://github.com/qyang-nj/llios/) repo and related writeups
- [Noah Martin](https://www.emergetools.com/blog/posts/iOS15LaunchTime) For the linked writeup on `LC_DYLD_CHAINED_FIXUPS`
- [blacktop](https://github.com/blacktop) All that awesome golang code in ipsw and related work, helped me get a better understanding of fixup chains.

**NOTE: The master branch is now obsolete, the macos branch works on both mobile OSes and macOS**


