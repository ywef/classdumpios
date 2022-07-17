class-dump-c
==========

# Background

This project is an amalgam of a few different versions of classdump. Initially based on a version by [DreamDevLost](https://github.com/DreamDevLost/classdumpios)
made as an iOS port from [nygard/class-dump](https://github.com/nygard/class-dump). From there I have manually merged in bits and pieces from various PR's against the original 
[ie #78](https://github.com/nygard/class-dump/pull/78) and then made a working macOS version again.

# Chained Fixups

In iOS 13 Apple introduced some new load commands into dyld (specifically `LC_DYLD_CHAINED_FIXUPS` and `LC_DYLD_EXPORTS_TRIE`) But didn't start widely using them
until iOS 15, once binaries are built with `-fixup_chains` any class-dump projects that relied on the old methodolgy would no longer work. [This writeup and related code](https://github.com/qyang-nj/llios/blob/main/dynamic_linking/chained_fixups.md) was instrumental in me understanding how to implement this newer methodology.

# Nitty gritty

My only prior experience with working on class dump was the cleanup work I did in classdump-dyld, I didn't really fully understand the process or how dyld and mach-o files fundamentally worked, and in getting this project updated and working I have a much better understanding. I can't overstate how much value I found in the resources gathered at [this repo](https://github.com/qyang-nj/llios) granted the open source apple code is available elsewhere for otools (cctools) et al, it's nice to have a central place of reference. 

I used`CDLCDyldInfo` as a template for the `CDLCChainedFixups` that does most of the heavy lifting for the newer process. It walks the fixup chains and stores the binds and the rebases in two separate dictionaries, which are subsequently referenced as applicable. The biggest 'gotchas' of this process were the need byte swap and/or bitshift in random circumstances for inexplicable reasons. The samples I modified from llios's macho-parser section (included in this repo in the `samples` folder) were instrumental in figuring this process out. Using some of the undocumented flags I added (-v,-d,-F,-z,-x etc..) On these sample files can give a better understanding on what im talking about, and the journey to figure all of this stuff out. The other big piece of the puzzle was making the adjustments for the differing `DYLD_CHAINED_PTR_64_OFFSET` vs `DYLD_CHAINED_PTR_64` pointer_format's when rebinding & rebasing.

# otool epiphany

While researching the new `LC_DYLD_CHAINED_FIXUPS` based world I was experimenting with `otool` output on the provided 'sample' files to see what kind of output I would get from the commands based around dumping the obj-c portions of the file and I noticed something curious when dumping iOS binaries.

## macOS:
![macos](https://github.com/lechium/classdumpios/blob/macos/Research/macos.png?raw=true) 

## iOS
![ios](https://github.com/lechium/classdumpios/blob/macos/Research/ios.png?raw=true)

Notice anything different? In the iOS section, even otool has trouble resolving the symbols i.e. `0x4790 (0x10000c460 extends past end of file)` Maybe because of entsize differences? (24 v 12)
            
I also noticed the 'rebased' addresses typically were identical with the upper bits being 'discarded'. ie `0x10000100007cc8` would become `0x100007CC8` So I thought, when I run into these scenarios where the offset would `extend past end of file` I would discard the upper bits and then re-add the `preferredLoadAddress` in an attempt to rectify this problem (preferredLoadAddress is re-added as an implementation detail to keep things working the same as the pre chained fixup workflow) Low and behold files that had failed to dump before would finally resolve missing symbols and stop crashing and burning, huzzah!

I apologize if any of my lingo isn't stated properly, this kind of bit/byte shifting chicanery has never been my strong suit, explaining this as best I can.

# Special Thanks:

- [Steve Nygard](https://github.com/nygard/) for the original class-dump
- [DreamDevLost](https://github.com/DreamDevLost/classdumpios) for his iOS port
- [Derek Selander](https://github.com/DerekSelander) for this amazing [writeup](https://derekselander.github.io/dsdump/)
- [Qing Yang](https://github.com/qyang-nj) For his [llios](https://github.com/qyang-nj/llios/) repo and related writeups
- [Noah Martin](https://www.emergetools.com/blog/posts/iOS15LaunchTime) For the linked writeup on `LC_DYLD_CHAINED_FIXUPS`
- [blacktop](https://github.com/blacktop) All that awesome golang code in ipsw and related work, helped me get a better understanding of fixup chains.

# Additional Reading:

- [MACHO-O LIBRE](https://www.first.org/resources/papers/conf2016/FIRST-2016-130.pdf)

**NOTE: The master branch is now obsolete, the macos branch works on both mobile OSes and macOS**


