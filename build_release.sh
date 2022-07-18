#!/bin/bash

XCP=$(/usr/bin/which xcpretty)

if [ -z $XCP ]; then
    xcodebuild -target classdumpios -configuration Release
    xcodebuild -target classdump -configuration Release
    xcodebuild -target classdump-ios -configuration Release
    xcodebuild -target classdumpios-bin -configuration Release
    xcodebuild -target classdumptvos-bin -configuration Release
else
    xcodebuild -target classdumpios -configuration Release | $XCP
    xcodebuild -target classdump -configuration Release | $XCP
    xcodebuild -target classdump-ios -configuration Release | $XCP
    xcodebuild -target classdumpios-bin -configuration Release | $XCP
    xcodebuild -target classdumptvos-bin -configuration Release | $XCP
fi

rm classdumpios-release
cp build/Release/classdumpios classdumpios-release
