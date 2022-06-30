// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "CDLCDynamicSymbolTable.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDRelocationInfo.h"

@implementation CDLCDynamicSymbolTable
{
    struct dysymtab_command _dysymtab;
    
    NSArray *_externalRelocationEntries;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _dysymtab.cmd     = [cursor readInt32];
        _dysymtab.cmdsize = [cursor readInt32];
        
        _dysymtab.ilocalsym      = [cursor readInt32];
        _dysymtab.nlocalsym      = [cursor readInt32];
        _dysymtab.iextdefsym     = [cursor readInt32];
        _dysymtab.nextdefsym     = [cursor readInt32];
        _dysymtab.iundefsym      = [cursor readInt32];
        _dysymtab.nundefsym      = [cursor readInt32];
        _dysymtab.tocoff         = [cursor readInt32];
        _dysymtab.ntoc           = [cursor readInt32];
        _dysymtab.modtaboff      = [cursor readInt32];
        _dysymtab.nmodtab        = [cursor readInt32];
        _dysymtab.extrefsymoff   = [cursor readInt32];
        _dysymtab.nextrefsyms    = [cursor readInt32];
        _dysymtab.indirectsymoff = [cursor readInt32];
        _dysymtab.nindirectsyms  = [cursor readInt32];
        _dysymtab.extreloff      = [cursor readInt32];
        _dysymtab.nextrel        = [cursor readInt32];
        _dysymtab.locreloff      = [cursor readInt32];
        _dysymtab.nlocrel        = [cursor readInt32];
#if 0
        DLog(@"ilocalsym:      0x%08x  %d", dysymtab.ilocalsym, dysymtab.ilocalsym);
        DLog(@"nlocalsym:      0x%08x  %d", dysymtab.nlocalsym, dysymtab.nlocalsym);
        DLog(@"iextdefsym:     0x%08x  %d", dysymtab.iextdefsym, dysymtab.iextdefsym);
        DLog(@"nextdefsym:     0x%08x  %d", dysymtab.nextdefsym, dysymtab.nextdefsym);
        DLog(@"iundefsym:      0x%08x  %d", dysymtab.iundefsym, dysymtab.iundefsym);
        DLog(@"nundefsym:      0x%08x  %d", dysymtab.nundefsym, dysymtab.nundefsym);
        
        DLog(@"tocoff:         0x%08x  %d", dysymtab.tocoff, dysymtab.tocoff);
        DLog(@"ntoc:           0x%08x  %d", dysymtab.ntoc, dysymtab.ntoc);
        DLog(@"modtaboff:      0x%08x  %d", dysymtab.modtaboff, dysymtab.modtaboff);
        DLog(@"nmodtab:        0x%08x  %d", dysymtab.nmodtab, dysymtab.nmodtab);
        
        DLog(@"extrefsymoff:   0x%08x  %d", dysymtab.extrefsymoff, dysymtab.extrefsymoff);
        DLog(@"nextrefsyms:    0x%08x  %d", dysymtab.nextrefsyms, dysymtab.nextrefsyms);
        DLog(@"indirectsymoff: 0x%08x  %d", dysymtab.indirectsymoff, dysymtab.indirectsymoff);
        DLog(@"nindirectsyms:  0x%08x  %d", dysymtab.nindirectsyms, dysymtab.nindirectsyms);
        
        DLog(@"extreloff:      0x%08x  %d", dysymtab.extreloff, dysymtab.extreloff);
        DLog(@"nextrel:        0x%08x  %d", dysymtab.nextrel, dysymtab.nextrel);
        DLog(@"locreloff:      0x%08x  %d", dysymtab.locreloff, dysymtab.locreloff);
        DLog(@"nlocrel:        0x%08x  %d", dysymtab.nlocrel, dysymtab.nlocrel);
#endif
        
        _externalRelocationEntries = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _dysymtab.cmd;
}

- (uint32_t)cmdsize;
{
    return _dysymtab.cmdsize;
}

- (void)loadSymbols;
{
    NSMutableArray *externalRelocationEntries = [[NSMutableArray alloc] init];
    
    CDMachOFileDataCursor *cursor = [[CDMachOFileDataCursor alloc] initWithFile:self.machOFile offset:_dysymtab.extreloff];

    DLog(@"indirectsymoff: %u", _dysymtab.indirectsymoff);
    DLog(@"nindirectsyms:  %u", _dysymtab.nindirectsyms);
#if 0
    [cursor setOffset:[self.machOFile offset] + dysymtab.indirectsymoff];
    for (uint32_t index = 0; index < dysymtab.nindirectsyms; index++) {
        // From loader.h: An indirect symbol table entry is simply a 32bit index into the symbol table to the symbol that the pointer or stub is referring to.
        uint32_t val = [cursor readInt32];
        DLog(@"%3u: %08x (%u)", index, val, val);
    }
#endif

    DLog(@"extreloff: %u", _dysymtab.extreloff);
    DLog(@"nextrel:   %u", _dysymtab.nextrel);
#ifdef DEBUG
    if (_dysymtab.nextrel > 0){
        DLog(@"     address   val       symbolnum  pcrel  len  ext  type");
        DLog(@"---  --------  --------  ---------  -----  ---  ---  ----");
    }
#endif
    for (uint32_t index = 0; index < _dysymtab.nextrel; index++) {
        struct relocation_info rinfo;

        rinfo.r_address = [cursor readInt32];
        uint32_t val    = [cursor readInt32];

        rinfo.r_symbolnum = val & 0x00ffffff;
        rinfo.r_pcrel     = (val & 0x01000000) >> 24;
        rinfo.r_length    = (val & 0x06000000) >> 25;
        rinfo.r_extern    = (val & 0x08000000) >> 27;
        rinfo.r_type      = (val & 0xf0000000) >> 28;
#ifdef DEBUG
        DLog(@"%3d: %08x  %08x   %08x      %01x    %01x    %01x     %01x", index, rinfo.r_address, val,
              rinfo.r_symbolnum, rinfo.r_pcrel, rinfo.r_length, rinfo.r_extern, rinfo.r_type);
#endif

        CDRelocationInfo *ri = [[CDRelocationInfo alloc] initWithInfo:rinfo];
        [externalRelocationEntries addObject:ri];
    }

    //DLog(@"externalRelocationEntries: %@", externalRelocationEntries);

    // r_address is purported to be the offset from the vmaddr of the first segment, but...
    // It seems to be from the first segment with r/w initprot.

    // it appears to be the offset from the vmaddr of the 3rd segment in t1s.
    // Actually, it really seems to be the offset from the vmaddr of the section indicated in the n_desc part of the nlist.
    // 0000000000000000 01 00 0500 0000000000000038 _OBJC_CLASS_$_NSObject
    // GET_LIBRARY_ORDINAL() from nlist.h for library.
    
    _externalRelocationEntries = [externalRelocationEntries copy];
}

// Just search for externals.
- (CDRelocationInfo *)relocationEntryWithOffset:(NSUInteger)offset;
{
    for (CDRelocationInfo *info in _externalRelocationEntries) {
        if (info.isExtern && info.offset == offset) {
            return info;
        }
    }

    return nil;
}

@end
