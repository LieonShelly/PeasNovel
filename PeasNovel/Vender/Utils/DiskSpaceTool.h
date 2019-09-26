//
//  DiskSpaceTool.h
//  PeasNovel
//
//  Created by lieon on 2019/4/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DiskSpaceTool : NSObject

+ (NSString *) freeDiskSpaceInBytes;//手机剩余空间
+ (NSString *) totalDiskSpaceInBytes;//手机总空间
//手机已用空间
+ (NSString *) usedDiskSpaceInBytes;

@end

NS_ASSUME_NONNULL_END
