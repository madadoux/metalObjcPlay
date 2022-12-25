//
//  Renderer.m
//  metalObjcPlay
//
//  Created by ME-MAC on 25/12/2022.
//
#import <string>
#import "Renderer.h"
#import "AAPLShaderTypes.h"
#import "AAPLTransforms.h"
#import <simd/simd.h>

@implementation Renderer

{
    // The device (aka GPU) used to render
    id<MTLDevice> _device;

    id<MTLRenderPipelineState> _pipelineState;

    // The command Queue used to submit commands.
    id<MTLCommandQueue> _commandQueue;

    // The Metal texture object
    id<MTLTexture> _texture;

    // The Metal buffer that holds the vertex data.
    id<MTLBuffer> _vertices;

    // The number of vertices in the vertex buffer.
    NSUInteger _numVertices;

    // The current size of the view.
    vector_uint2 _viewportSize;
    
    double time;
}



- (instancetype)initWithMTKView:(MTKView *)view {
    self = [super init];
    if (self) {
        _device = view.device;
        MTKTextureLoader *loader  = [[MTKTextureLoader alloc] initWithDevice:_device];
        
        NSURL *imageUrl = [[NSBundle mainBundle] URLForResource:@"textureExample" withExtension:@"png"];
        _texture = [loader newTextureWithContentsOfURL:imageUrl options:nil error:nil];
        
        
        AAPLVertex quadVertices[] = {
            // first triangle
            { {  250,  -250 },  { 1.f, 1.f } },
            { { -250,  -250 },  { 0.f, 1.f } },
            { { -250,   250 },  { 0.f, 0.f } },
            // second triangle
            { {  250,  -250 },  { 1.f, 1.f } },
            { { -250,   250 },  { 0.f, 0.f } },
            { {  250,   250 },  { 1.f, 0.f } },
            
        };
        
        
        _vertices = [_device newBufferWithBytes:quadVertices
                                         length:sizeof(quadVertices)
                                        options:MTLResourceStorageModeShared];
        
        _numVertices = sizeof(quadVertices) / sizeof(AAPLVertex);
        
        
        _commandQueue = [_device newCommandQueue];
        
        id<MTLLibrary> shaderLib = [_device newDefaultLibrary];
        
        MTLRenderPipelineDescriptor *renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        
        
        renderDescriptor.label = @"Texturing Pipeline";
        renderDescriptor.vertexFunction = [shaderLib newFunctionWithName:@"vertexShader"];
        renderDescriptor.fragmentFunction = [shaderLib newFunctionWithName:@"samplingShader"];
        renderDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        
        NSError *error;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:&error];
        
        
        if (error != nil ){
            NSLog(@"failed to creader the render state %@ " , error.description);
        }
        
        
    }
    
    return self;
}
- (void)drawInMTKView:(nonnull MTKView *)view {
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"my command buffer";
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
   
    [commandEncoder setViewport:(MTLViewport){0.0, 0.0, static_cast<double>(_viewportSize.x), static_cast<double>(_viewportSize.y), -1.0, 1.0 }];

    [commandEncoder setRenderPipelineState:_pipelineState];
    
    [commandEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
    
    [commandEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
    /*   let modelMatrix = float4x4(rotationAbout: float3(0, 1, 0), by: angle) *  float4x4(scaleBy: 2)
     
     let viewMatrix = float4x4(translationBy: float3(0, 0, -2))
     let modelViewMatrix = viewMatrix * modelMatrix
     let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
     let projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
     
     var uniforms = Uniforms(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix)
     */
    using namespace AAPL;
    time += view.preferredFramesPerSecond;
    
    // TRS matrix
    simd::float4x4 transformationMatrix = Math::scale(1.5, 1.5, 1) * Math::rotate(time/60, 0, 0, 1) * AAPL::Math::translate(-0.0, 0.3, .0)  ;
    
    [commandEncoder setVertexBytes:&transformationMatrix length:sizeof(transformationMatrix) atIndex:AAPLVertexMVPMatrix];
    
    [commandEncoder setFragmentTexture:_texture atIndex:AAPLTextureIndexBaseColor];
    
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
    
    [commandEncoder endEncoding];
    
    
    [commandBuffer presentDrawable: view.currentDrawable];
    
    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

@end
