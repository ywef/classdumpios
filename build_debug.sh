#!/bin/zsh

XCP=$(/usr/bin/which xcpretty)

if [ -z $XCP ]; then
    xcodebuild -target classdumpc -configuration Debug
    xcodebuild -target classdump -configuration Debug
    xcodebuild -target classdump-ios -configuration Debug
    xcodebuild -target classdumpc-bin -configuration Debug
    xcodebuild -target classdumptvos-bin -configuration Debug
else
    xcodebuild -target classdumpc -configuration Debug | $XCP
    xcodebuild -target classdump -configuration Debug | $XCP
    xcodebuild -target classdump-ios -configuration Debug | $XCP
    xcodebuild -target classdumpc-bin -configuration Debug | $XCP
    xcodebuild -target classdumptvos-bin -configuration Debug | $XCP
fi
