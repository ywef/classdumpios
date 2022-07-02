//
//  CDLCChainedFixups.m
//  classdumpios
//
//  Created by kevinbradley on 6/26/22.
//

// Massive thanks to this repo and everything in it to help me get a better handle on DYLD_CHAINED_FIXUPS https://github.com/qyang-nj/llios/blob/main/dynamic_linking/chained_fixups.md

#import "CDLCChainedFixups.h"
#include <mach-o/loader.h>
#include <mach-o/fixup-chains.h>
#import "CDLCSegment.h"
#import "CDLCSymbolTable.h"
#import "NSData+Flip.h"
#import "CDSymbol.h"

@implementation CDLCChainedFixups
{
    struct linkedit_data_command _linkeditDataCommand;
    NSData *_linkeditData;
    NSUInteger _ptrSize;
    NSMutableDictionary *_symbolNamesByAddress;
    NSMutableDictionary *_based;
}


static void printChainedFixupsHeader(struct dyld_chained_fixups_header *header) {
    const char *imports_format = NULL;
    switch (header->imports_format) {
        case DYLD_CHAINED_IMPORT: imports_format = "DYLD_CHAINED_IMPORT"; break;
        case DYLD_CHAINED_IMPORT_ADDEND: imports_format = "DYLD_CHAINED_IMPORT_ADDEND"; break;
        case DYLD_CHAINED_IMPORT_ADDEND64: imports_format = "DYLD_CHAINED_IMPORT_ADDEND64"; break;
    }
    if ([CDClassDump printFixupData]){
        fprintf(stderr,"  CHAINED FIXUPS HEADER\n");
        fprintf(stderr,"    fixups_version : %d\n", header->fixups_version);
        fprintf(stderr,"    starts_offset  : %#4x (%d)\n", header->starts_offset, header->starts_offset);
        fprintf(stderr,"    imports_offset : %#4x (%d)\n", header->imports_offset, header->imports_offset);
        fprintf(stderr,"    symbols_offset : %#4x (%d)\n", header->symbols_offset, header->symbols_offset);
        fprintf(stderr,"    imports_count  : %d\n", header->imports_count);
        fprintf(stderr,"    imports_format : %d (%s)\n", header->imports_format, imports_format);
        fprintf(stderr,"    symbols_format : %d (%s)\n", header->symbols_format,
                (header->symbols_format == 0 ? "UNCOMPRESSED" : "ZLIB COMPRESSED"));
        fprintf(stderr,"\n");
    }
    
}

- (void)printFixupsInPage:(uint8_t *)base fixupBase:(uint8_t*)fixupBase header:(struct dyld_chained_fixups_header *)header startsIn:(struct dyld_chained_starts_in_segment *)segment page:(int)pageIndex {
    uint32_t chain = (uint32_t)segment->segment_offset + segment->page_size * pageIndex + segment->page_start[pageIndex];
    bool done = false;
    int count = 0;
    while (!done) {
        if (segment->pointer_format == DYLD_CHAINED_PTR_64
            || segment->pointer_format == DYLD_CHAINED_PTR_64_OFFSET) {
            struct dyld_chained_ptr_64_bind bind = *(struct dyld_chained_ptr_64_bind *)(base + chain);
            if (bind.bind) {
                struct dyld_chained_import import = ((struct dyld_chained_import *)(fixupBase + header->imports_offset))[bind.ordinal];
                char *symbol = (char *)(fixupBase + header->symbols_offset + import.name_offset);
                NSData *data = [[NSData alloc] initWithBytes:[self.machOFile bytesAtOffset:chain] length:sizeof(uint64_t)];
                //DLog(@"BIND data: %@", data);
                NSNumberFormatter *formatter = [NSNumberFormatter new];
                [formatter numberFromString:[[data reverse] decimalString]];
                NSNumber     *myNSNumber          = [formatter numberFromString:[[data reverse] decimalString]];
                //OLog(@"myNSNumber", [myNSNumber unsignedIntegerValue]);
                uint64_t raw = [myNSNumber unsignedIntegerValue];
                InfoLog(@"reverse: %@ raw: %@", [[data reverse] hexString], [data hexString]);
                if ([CDClassDump printFixupData]){
                    fprintf(stderr,"        0x%08x RAW: %#010llx  BIND     ordinal: %d   addend: %d    reserved: %d   (%s)\n",
                            chain, raw, bind.ordinal, bind.addend, bind.reserved, symbol);
                }
                [self bindAddress:raw type:0 symbolName:symbol flags:bind.reserved addend:bind.addend libraryOrdinal:bind.ordinal];
                [self bindAddress:chain type:0 symbolName:symbol flags:bind.reserved addend:bind.addend libraryOrdinal:bind.ordinal];
                [self bindAddress:(uint64_t)[data bytes] type:0 symbolName:symbol flags:bind.reserved addend:bind.addend libraryOrdinal:bind.ordinal];
                [self rebaseAddress:(uint64_t)[data bytes] target:chain];
                [self rebaseAddress:raw target:chain];
            } else {
                // rebase 0x%08lx
                struct dyld_chained_ptr_64_rebase rebase = *(struct dyld_chained_ptr_64_rebase *)&bind;
                
                
                NSData *data = [[NSData alloc] initWithBytes:[self.machOFile bytesAtOffset:chain] length:sizeof(uint64_t)];
                //VerboseLog(@"RAW: %@", [data reverse]);
                //VerboseLog(@"RAW: %@ (%lu)", [[data reverse] stringFromHexData], [[data decimalString] integerValue]);
                uint64_t raw = [[data decimalString] integerValue];
                //ODLog(@"RAW", [[data reverse] stringFromHexData]);
                InfoLog(@"reverse: %@ raw: %@", [[data reverse] hexString], [data hexString]);
                if ([CDClassDump printFixupData]){
                    fprintf(stderr,"        %#010x RAW: %#010llx REBASE   target: %#010llx   high8: %#010x\n",
                            chain, raw, rebase.target, rebase.high8);
                }
                [self rebaseAddress:raw target:rebase.target];
                [self rebaseAddress:(uint64_t)[data bytes] target:rebase.target];
            }
            
            if (bind.next == 0) {
                done = true;
            } else {
                chain += bind.next * 4;
            }
            
        } else {
            printf("Unsupported pointer format: 0x%x", segment->pointer_format);
            break;
        }
        count++;
    }
}


static void formatPointerFormat(uint16_t pointer_format, char *formatted) {
    switch(pointer_format) {
        case DYLD_CHAINED_PTR_ARM64E: strcpy(formatted, "DYLD_CHAINED_PTR_ARM64E"); break;
        case DYLD_CHAINED_PTR_64: strcpy(formatted, "DYLD_CHAINED_PTR_64"); break;
        case DYLD_CHAINED_PTR_32: strcpy(formatted, "DYLD_CHAINED_PTR_32"); break;
        case DYLD_CHAINED_PTR_32_CACHE: strcpy(formatted, "DYLD_CHAINED_PTR_32_CACHE"); break;
        case DYLD_CHAINED_PTR_32_FIRMWARE: strcpy(formatted, "DYLD_CHAINED_PTR_32_FIRMWARE"); break;
        case DYLD_CHAINED_PTR_64_OFFSET: strcpy(formatted, "DYLD_CHAINED_PTR_64_OFFSET"); break;
        case DYLD_CHAINED_PTR_ARM64E_KERNEL: strcpy(formatted, "DYLD_CHAINED_PTR_ARM64E_KERNEL"); break;
        case DYLD_CHAINED_PTR_64_KERNEL_CACHE: strcpy(formatted, "DYLD_CHAINED_PTR_64_KERNEL_CACHE"); break;
        case DYLD_CHAINED_PTR_ARM64E_USERLAND: strcpy(formatted, "DYLD_CHAINED_PTR_ARM64E_USERLAND"); break;
        case DYLD_CHAINED_PTR_ARM64E_FIRMWARE: strcpy(formatted, "DYLD_CHAINED_PTR_ARM64E_FIRMWARE"); break;
        case DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE: strcpy(formatted, "DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE"); break;
        case DYLD_CHAINED_PTR_ARM64E_USERLAND24: strcpy(formatted, "DYLD_CHAINED_PTR_ARM64E_USERLAND24"); break;
        default: strcpy(formatted, "UNKNOWN");
    }
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _linkeditDataCommand.cmd     = [cursor readInt32];
        _linkeditDataCommand.cmdsize = [cursor readInt32];
        
        _linkeditDataCommand.dataoff  = [cursor readInt32];
        _linkeditDataCommand.datasize = [cursor readInt32];
        _ptrSize = [[cursor machOFile] ptrSize];
        //[[self.machOFile symbolTable] baseAddress];
        _symbolNamesByAddress = [NSMutableDictionary new];
        _based = [NSMutableDictionary new];
    }
    
    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _linkeditDataCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return _linkeditDataCommand.cmdsize;
}

- (NSData *)linkeditData;
{
    if (_linkeditData == NULL) {
        _linkeditData = [[NSData alloc] initWithBytes:[self.machOFile bytesAtOffset:_linkeditDataCommand.dataoff] length:_linkeditDataCommand.datasize];
    }
    
    return _linkeditData;
}

- (NSString *)externalClassNameForAddress:(NSUInteger)address;
{
    NSString *str = [self symbolNameForAddress:address];
    
    if (str != nil) {
        if ([str hasPrefix:ObjCClassSymbolPrefix]) {
            return [str substringFromIndex:[ObjCClassSymbolPrefix length]];
        } else {
            DLog(@"Warning: Unknown prefix on symbol name... %@ (addr %lx)", str, address);
            return str;
        }
    }
    
    return nil;
}

- (NSString *)symbolNameForAddress:(NSUInteger)address;
{
    return [_symbolNamesByAddress objectForKey:[NSNumber numberWithUnsignedInteger:address]];
}

- (NSUInteger)rebaseTargetFromAddress:(NSUInteger)address adjustment:(NSUInteger)adj {
    InfoLog(@"%s : %#010llx (%lu)", _cmds, address-adj, address-adj);
    NSNumber *key = [NSNumber numberWithUnsignedInteger:address-adj]; // I don't think 32-bit will dump 64-bit stuff.
    return [_based[key] unsignedIntegerValue];
}

- (void)rebaseAddress:(uint64_t)address target:(uint64_t)target
{
    NSNumber *key = [NSNumber numberWithUnsignedInteger:address]; // I don't think 32-bit will dump 64-bit stuff.
    NSNumber *val = [NSNumber numberWithUnsignedInteger:target];
    _based[key] = val;
}

- (void)bindAddress:(uint64_t)address type:(uint8_t)type symbolName:(const char *)symbolName flags:(uint8_t)flags
             addend:(int64_t)addend libraryOrdinal:(int64_t)libraryOrdinal;
{
#if 0
    VerboseLog(@"    Bind address: %016lx, type: 0x%02x, flags: %02x, addend: %016lx, libraryOrdinal: %ld, symbolName: %s",
               address, type, flags, addend, libraryOrdinal, symbolName);
#endif
    
    NSNumber *key = [NSNumber numberWithUnsignedInteger:address]; // I don't think 32-bit will dump 64-bit stuff.
    NSString *str = [[NSString alloc] initWithUTF8String:symbolName];
    _symbolNamesByAddress[key] = str;
}

- (void)machOFileDidReadLoadCommands:(CDMachOFile *)machOFile;
{
    uint8_t *fixup_base = (uint8_t *)[[self linkeditData] bytes];
    struct dyld_chained_fixups_header *header = (struct dyld_chained_fixups_header *)fixup_base;
    printChainedFixupsHeader(header);
    struct dyld_chained_starts_in_image *starts_in_image =
    (struct dyld_chained_starts_in_image *)(fixup_base + header->starts_offset);
    
    uint32_t *offsets = starts_in_image->seg_info_offset;
    for (int i = 0; i < starts_in_image->seg_count; ++i) {
        CDLCSegment *segCmd = self.machOFile.segments[i];
        //struct segment_command_64 *segCmd = machoBinary.segmentCommands[i];
        if ([CDClassDump printFixupData]){
            fprintf(stderr,"  SEGMENT %.16s (offset: %d)\n", [segCmd.name UTF8String], offsets[i]);
        }
        if (offsets[i] == 0) {
            if ([CDClassDump printFixupData]){
                fprintf(stderr,"\n");
            }
            continue;
        }
        
        struct dyld_chained_starts_in_segment* startsInSegment = (struct dyld_chained_starts_in_segment*)(fixup_base + header->starts_offset + offsets[i]);
        char formatted_pointer_format[256];
        formatPointerFormat(startsInSegment->pointer_format, formatted_pointer_format);
        if ([CDClassDump printFixupData]){
            fprintf(stderr,"    size: %d\n", startsInSegment->size);
            fprintf(stderr,"    page_size: 0x%x\n", startsInSegment->page_size);
            fprintf(stderr,"    pointer_format: %d (%s)\n", startsInSegment->pointer_format, formatted_pointer_format);
            fprintf(stderr,"    segment_offset: 0x%llx\n", startsInSegment->segment_offset);
            fprintf(stderr,"    max_valid_pointer: %d\n", startsInSegment->max_valid_pointer);
            fprintf(stderr,"    page_count: %d\n", startsInSegment->page_count);
            fprintf(stderr,"    page_start: %d\n", startsInSegment-> page_start[0]);
        }
        uint16_t *page_starts = startsInSegment->page_start;
        uint16_t maxPageNum = UINT16_MAX;
        int pageCount = 0;
        for (int j = 0; j < MIN(startsInSegment->page_count, maxPageNum); ++j) {
            if ([CDClassDump printFixupData]){
                fprintf(stderr,"      PAGE %d (offset: %d)\n", j, page_starts[j]);
            }
            if (page_starts[j] == DYLD_CHAINED_PTR_START_NONE) { continue; }
            
            [self printFixupsInPage:(uint8_t *)[self.machOFile bytes] fixupBase:fixup_base header:header startsIn:startsInSegment page:j];
            //printFixupsInPage((uint8_t *)[self.machOFile bytes], fixup_base, header, startsInSegment, j);
            
            pageCount++;
            if ([CDClassDump printFixupData]){
                fprintf(stderr,"\n");
            }
        }
        if ([CDClassDump printFixupData]){
            DLog(@"symbolNamesByAddress: %@", _symbolNamesByAddress);
            DLog(@"based: %@", _based);
        }
    }
}


@end
