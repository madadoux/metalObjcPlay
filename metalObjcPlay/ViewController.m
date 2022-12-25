//
//  ViewController.m
//  metalObjcPlay
//
//  Created by ME-MAC on 25/12/2022.
//

#import "ViewController.h"
#import "Renderer.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
@interface ViewController ()

@end

@implementation ViewController
{
    MTKView *_metalView;

    Renderer *_renderer;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _metalView = (MTKView*) self.view;
    
    _metalView.device = MTLCreateSystemDefaultDevice();
    
    
    
    _renderer = [[Renderer alloc] initWithMTKView:_metalView];
    // Initialize the renderer with the view size
    [_renderer mtkView:_metalView drawableSizeWillChange:_metalView.drawableSize];
    _metalView.delegate = _renderer;
    
}


@end
