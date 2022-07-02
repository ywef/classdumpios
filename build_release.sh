#!/bin/bash

xcodebuild -target classdumpios -configuration Release | xcpretty
rm classdumpios-release
cp build/Release/classdumpios classdumpios-release
