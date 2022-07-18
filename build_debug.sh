#!/bin/zsh

XCP=$(/usr/bin/which xcpretty)

if [ -z $XCP ]; then
    xcodebuild -target classdumpios -configuration Debug
    xcodebuild -target classdump -configuration Debug
    xcodebuild -target classdump-ios -configuration Debug
    xcodebuild -target classdumpios-bin -configuration Debug
    xcodebuild -target classdumptvos-bin -configuration Debug
else
    xcodebuild -target classdumpios -configuration Debug | $XCP
    xcodebuild -target classdump -configuration Debug | $XCP
    xcodebuild -target classdump-ios -configuration Debug | $XCP
    xcodebuild -target classdumpios-bin -configuration Debug | $XCP
    xcodebuild -target classdumptvos-bin -configuration Debug | $XCP
fi
