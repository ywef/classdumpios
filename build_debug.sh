#!/bin/zsh

xcodebuild -target classdumpios -configuration Debug | xcpretty
xcodebuild -target classdump -configuration Debug | xcpretty
xcodebuild -target classdump-ios -configuration Debug | xcpretty

