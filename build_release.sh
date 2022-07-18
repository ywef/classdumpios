#!/bin/bash

XCP=$(/usr/bin/which xcpretty)

if [ -z $XCP ]; then
    xcodebuild -target classdumpc -configuration Release
    xcodebuild -target classdump -configuration Release
    xcodebuild -target classdump-ios -configuration Release
    xcodebuild -target classdumpc-ios -configuration Release
    xcodebuild -target classdumpc-tvos -configuration Release
else
    xcodebuild -target classdumpc -configuration Release | $XCP
    xcodebuild -target classdump -configuration Release | $XCP
    xcodebuild -target classdump-ios -configuration Release | $XCP
    xcodebuild -target classdumpc-ios -configuration Release | $XCP
    xcodebuild -target classdumpc-tvos -configuration Release | $XCP
fi

rm classdumpc-release
cp build/Release/classdumpc classdumpc-release
