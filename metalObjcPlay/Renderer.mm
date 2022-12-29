//
//  Renderer.m
//  metalObjcPlay
//
//  Created by ME-MAC on 25/12/2022.
//
#import "Renderer.h"
#import "AAPLShaderTypes.h"
#import "AAPLTransforms.h"
#import <simd/simd.h>
#import <string>

@implementation Renderer

{
  // The device (aka GPU) used to render
  id<MTLDevice> _device;

  id<MTLRenderPipelineState> _pipelineState;

  id<MTLDepthStencilState> _depthState;

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

    // Indicate that each pixel in the depth buffer is a 32-bit floating point
    // value.
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    // init all with ones
    view.clearDepth = 1.0;

    MTKTextureLoader *loader =
        [[MTKTextureLoader alloc] initWithDevice:_device];

    NSURL *imageUrl = [[NSBundle mainBundle] URLForResource:@"textureExample"
                                              withExtension:@"png"];
    _texture = [loader newTextureWithContentsOfURL:imageUrl
                                           options:nil
                                             error:nil];

    _commandQueue = [_device newCommandQueue];

    id<MTLLibrary> shaderLib = [_device newDefaultLibrary];

    MTLRenderPipelineDescriptor *renderDescriptor =
        [[MTLRenderPipelineDescriptor alloc] init];

    renderDescriptor.label = @"Texturing Pipeline";
    renderDescriptor.vertexFunction =
        [shaderLib newFunctionWithName:@"vertexShader"];
    renderDescriptor.fragmentFunction =
        [shaderLib newFunctionWithName:@"samplingShader"];
    renderDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    renderDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;

    NSError *error;
    _pipelineState =
        [_device newRenderPipelineStateWithDescriptor:renderDescriptor
                                                error:&error];

    MTLDepthStencilDescriptor *depthDesc =
        [[MTLDepthStencilDescriptor alloc] init];
    depthDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
    depthDesc.depthWriteEnabled = true;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthDesc];

    if (error != nil) {
      NSLog(@"failed to creader the render state %@ ", error.description);
    }
  }

  return self;
}
- (void)drawInMTKView:(nonnull MTKView *)view {

  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  commandBuffer.label = @"my command buffer";

  MTLRenderPassDescriptor *renderPassDescriptor =
      view.currentRenderPassDescriptor;

  id<MTLRenderCommandEncoder> commandEncoder =
      [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

  [commandEncoder
      setViewport:(MTLViewport){0.0, 0.0, static_cast<double>(_viewportSize.x),
                                static_cast<double>(_viewportSize.y), -1.0,
                                1.0}];
  [commandEncoder setCullMode: MTLCullModeBack];
  [commandEncoder setRenderPipelineState:_pipelineState];
  [commandEncoder setDepthStencilState:_depthState];

  AAPLVertex quadVertices[] = {
      // first triangle
      {{250, -250, .5f, 1}, {1.f, 1.f}, {.5f, 0.5f, .5f}},
      {{-250, -250, .5f, 1}, {0.f, 1.f}, {.5f, 0.5f, .5f}},
      {{-250, 250, .5f, 1}, {0.f, 0.f}, {.5f, 0.5f, .5f}},
      // second triangle
      {{250, -250, .5f, 1}, {1.f, 1.f}, {.5f, 0.5f, .5f}},
      {{-250, 250, .5f, 1}, {0.f, 0.f}, {.5f, 0.5f, .5f}},
      {{250, 250, .5f, 1}, {1.f, 0.f}, {.5f, 0.5f, .5f}},
  };

  _vertices = [_device newBufferWithBytes:quadVertices
                                   length:sizeof(quadVertices)
                                  options:MTLResourceStorageModeShared];

  [commandEncoder setVertexBuffer:_vertices
                           offset:0
                          atIndex:AAPLVertexInputIndexVertices];

  [commandEncoder setVertexBytes:&_viewportSize
                          length:sizeof(_viewportSize)
                         atIndex:AAPLVertexInputIndexViewportSize];

  using namespace AAPL;
  time += view.preferredFramesPerSecond;

  // TRS matrix
  simd::float4x4 transformationMatrix = Math::scale(1.5, 1.5, 1) *
                                        Math::rotate(time / 60, 0, 1, 0) *
                                        AAPL::Math::translate(-0.0, 0.3, .0);

  [commandEncoder setVertexBytes:&transformationMatrix
                          length:sizeof(transformationMatrix)
                         atIndex:AAPLVertexMVPMatrix];

  [commandEncoder setFragmentTexture:_texture
                             atIndex:AAPLTextureIndexBaseColor];

  bool hasNoTexture = false;
  [commandEncoder setFragmentBytes:&hasNoTexture
                            length:sizeof(hasNoTexture)
                           atIndex:AAPLFragmentHasNoTexture];

  [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                     vertexStart:0
                     vertexCount:6];

  AAPLVertex triangleVertices[] = {
      // first triangle
      {{100, -550, 0.f, 1}, {1.f, 1.f}, {1.f, 0.f, 1.f}},
      {{-100, -450, 0, 1}, {0.f, 1.f}, {1.f, 1.f, 0.f}},
      {{-100, 250, 1.0, 1}, {0.f, 0.f}, {0.f, 1.f, 1.f}},
  };

  id<MTLBuffer> triVertices =
      [_device newBufferWithBytes:triangleVertices
                           length:sizeof(triangleVertices)
                          options:MTLResourceStorageModeShared];

  [commandEncoder setVertexBuffer:triVertices
                           offset:0
                          atIndex:AAPLVertexInputIndexVertices];
    
  simd::float4x4 transformationMatrix1 = matrix_identity_float4x4;
   
  [commandEncoder setVertexBytes:&transformationMatrix1
                            length:sizeof(transformationMatrix1)
                           atIndex:AAPLVertexMVPMatrix];
  hasNoTexture = true;
  [commandEncoder setFragmentBytes:&hasNoTexture
                            length:sizeof(hasNoTexture)
                           atIndex:AAPLFragmentHasNoTexture];

  [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                     vertexStart:0
                     vertexCount:3];

  [commandEncoder endEncoding];

  [commandBuffer presentDrawable:view.currentDrawable];

  [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  _viewportSize.x = size.width;
  _viewportSize.y = size.height;
}

@end
