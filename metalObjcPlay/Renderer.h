//
//  Renderer.h
//  metalObjcPlay
//
//  Created by ME-MAC on 25/12/2022.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject<MTKViewDelegate,UITableViewDelegate>
- (instancetype) initWithMTKView: (MTKView*) view;
@end

NS_ASSUME_NONNULL_END
