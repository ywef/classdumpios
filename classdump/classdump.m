//
//  classdump.m
//  classdump
//
//  Created by Kevin Bradley on 6/21/22.
//

#import "classdump.h"

@implementation classdump

+ (NSInteger)performClassDumpOnFile:(NSString *)file toFolder:(NSString *)outputPath {
    
    CDClassDump *classDump = [[CDClassDump alloc] init];
    classDump.shouldShowIvarOffsets = true;
    classDump.shouldShowMethodAddresses = true;
    NSString *executablePath = [file executablePathForFilename];
    if (executablePath){
        classDump.searchPathState.executablePath = executablePath;
        CDFile *file = [CDFile fileWithContentsOfFile:executablePath searchPathState:classDump.searchPathState];
        if (file == nil) {
            NSFileManager *defaultManager = [NSFileManager defaultManager];
            
            if ([defaultManager fileExistsAtPath:executablePath]) {
                if ([defaultManager isReadableFileAtPath:executablePath]) {
                    fprintf(stderr, "class-dump: Input file (%s) is neither a Mach-O file nor a fat archive.\n", [executablePath UTF8String]);
                } else {
                    fprintf(stderr, "class-dump: Input file (%s) is not readable (check read permissions).\n", [executablePath UTF8String]);
                }
            } else {
                fprintf(stderr, "class-dump: Input file (%s) does not exist.\n", [executablePath UTF8String]);
            }

            return 1;
        }
        
        //got this far file is not nil
        CDArch targetArch;
        if ([file bestMatchForLocalArch:&targetArch] == NO) {
            fprintf(stderr, "Error: Couldn't get local architecture\n");
            return 1;
        }
        //NSLog(@"No arch specified, best match for local arch is: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
        classDump.targetArch = targetArch;
        classDump.searchPathState.executablePath = [executablePath stringByDeletingLastPathComponent];
        
        NSError *error;
        if (![classDump loadFile:file error:&error]) {
            fprintf(stderr, "Error: %s\n", [[error localizedFailureReason] UTF8String]);
            return 1;
        } else {
            [classDump processObjectiveCData];
            [classDump registerTypes];
            CDMultiFileVisitor *multiFileVisitor = [[CDMultiFileVisitor alloc] init];
            multiFileVisitor.classDump = classDump;
            classDump.typeController.delegate = multiFileVisitor;
            multiFileVisitor.outputPath = outputPath;
            [classDump recursivelyVisit:multiFileVisitor];
        }
    } else {
        NSLog(@"no exe path found for: %@", file);
        return -1;
    }
    return 0;
}

@end
