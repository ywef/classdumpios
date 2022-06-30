//
//  CDLCChainedFixups.h
//  classdumpios
//
//  Created by kevinbradley on 6/26/22.
//

#import <classdump/classdump.h>
#import "CDLoadCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface CDLCChainedFixups : CDLoadCommand
- (NSUInteger)rebaseTargetFromAddress:(NSUInteger)address;
@end

NS_ASSUME_NONNULL_END
