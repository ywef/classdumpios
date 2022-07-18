#!/bin/zsh

XCP=$(/usr/bin/which xcpretty)

if [ -z $XCP ]; then
    xcodebuild -target classdumpc -configuration Debug
    xcodebuild -target classdump -configuration Debug
    xcodebuild -target classdump-ios -configuration Debug
    xcodebuild -target classdumpc-ios -configuration Debug
    xcodebuild -target classdumpc-tvos -configuration Debug
else
    xcodebuild -target classdumpc -configuration Debug | $XCP
    xcodebuild -target classdump -configuration Debug | $XCP
    xcodebuild -target classdump-ios -configuration Debug | $XCP
    xcodebuild -target classdumpc-ios -configuration Debug | $XCP
    xcodebuild -target classdumpc-tvos -configuration Debug | $XCP
fi
