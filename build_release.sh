#!/bin/bash

xcodebuild -target classdumpios -configuration Release | xcpretty
cp build/Release/classdumpios classdumpios-release
