// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDFindMethodVisitor.h"

#import "CDClassDump.h"
#import "CDObjectiveC1Processor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCMethod.h"
//#import "CDTypeController.h"

@interface CDFindMethodVisitor ()
@property (readonly) NSMutableString *resultString;
@property (nonatomic, strong) CDOCProtocol *context;
@property (assign) BOOL hasShownContext;
@end

#pragma mark -

@implementation CDFindMethodVisitor
{
    NSString *_searchString;
    NSMutableString *_resultString;
    CDOCProtocol *_context;
    BOOL _hasShownContext;
}

- (id)init;
{
    if ((self = [super init])) {
        _searchString = nil;
        _resultString = [[NSMutableString alloc] init];
        _context = nil;
        _hasShownContext = NO;
    }

    return self;
}

#pragma mark -

- (void)willBeginVisiting;
{
    LOG_CMD;
    [self.classDump appendHeaderToString:self.resultString];

    if (self.classDump.hasObjectiveCRuntimeInfo) {
        //[[classDump typeController] appendStructuresToString:resultString symbolReferences:nil];
        //[resultString appendString:@"// [structures go here]\n"];
    }
}

- (void)visitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
    LOG_CMD;
    if (!self.classDump.hasObjectiveCRuntimeInfo) {
        [self.resultString appendString:@"//\n"];
        [self.resultString appendString:@"// This file does not contain any Objective-C runtime information.\n"];
        [self.resultString appendString:@"//\n"];
    }
}

- (void)didEndVisiting;
{
    LOG_CMD;
    [self writeResultToStandardOutput];
}

- (void)writeResultToStandardOutput;
{
    LOG_CMD;
    NSData *data = [self.resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    LOG_CMD;
    [self setContext:protocol];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    LOG_CMD;
    if (self.hasShownContext)
        [self.resultString appendString:@"\n"];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    LOG_CMD;
    [self setContext:aClass];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    LOG_CMD;
    if (self.hasShownContext)
        [self.resultString appendString:@"\n"];
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
}

- (void)willVisitCategory:(CDOCCategory *)category;
{
    LOG_CMD;
    [self setContext:category];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    LOG_CMD;
    if (self.hasShownContext)
        [self.resultString appendString:@"\n"];
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
    LOG_CMD;
    NSRange range = [method.name rangeOfString:self.searchString];
    if (range.length > 0) {
        [self showContextIfNecessary];

        [self.resultString appendString:@"+ "];
        [method appendToString:self.resultString typeController:self.classDump.typeController];
        [self.resultString appendString:@"\n"];
    }
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
    LOG_CMD;
    NSRange range = [method.name rangeOfString:self.searchString];
    if (range.length > 0) {
        [self showContextIfNecessary];

        [self.resultString appendString:@"- "];
        [method appendToString:self.resultString typeController:self.classDump.typeController];
        [self.resultString appendString:@"\n"];
    }
}

- (void)visitIvar:(CDOCInstanceVariable *)ivar;
{
}

#pragma mark -

- (void)setContext:(CDOCProtocol *)newContext;
{
    LOG_CMD;
    if (newContext != _context) {
        _context = newContext;
        self.hasShownContext = NO;
    }
}

- (void)showContextIfNecessary;
{
    LOG_CMD;
    if (self.hasShownContext == NO) {
        [self.resultString appendString:[self.context methodSearchContext]];
        [self.resultString appendString:@"\n"];
        self.hasShownContext = YES;
    }
}

@end
