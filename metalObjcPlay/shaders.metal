//
//  shaders.metal
//  metalObjcPlay
//
//  Created by ME-MAC on 25/12/2022.
//

#include <metal_stdlib>
using namespace metal;


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#include "AAPLShaderTypes.h"

struct RasterizerData
{
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer
    // will interpolate its value with values of other vertices making up the triangle
    // and pass that interpolated value to the fragment shader for each fragment in
    // that triangle.
    float2 textureCoordinate;
    
    float2 viewportSize;
    float3 color;

};

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant AAPLVertex *vertexArray [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(AAPLVertexInputIndexViewportSize) ]],
             constant float4x4 *mvp [[buffer(AAPLVertexMVPMatrix)]]
             
             )

{

    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    //   Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    //   the origin)
    float4 pixelSpacePosition = vertexArray[vertexID].position;

    // Get the viewport size and cast to float.
    float2 viewportSize = float2(*viewportSizePointer);

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = pixelSpacePosition;
    
    out.position.xy = out.position.xy / (viewportSize / 2.0);

    out.position =  (*mvp *  out.position);
    //pixelSpacePosition =   out.position.xy;
    //out.position.z = vertexArray[vertexID].position.z;
    // Pass the input textureCoordinate straight to the output RasterizerData. This value will be
    //   interpolated with the other textureCoordinate values in the vertices that make up the
    //   triangle.
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    out.viewportSize = viewportSize;
    out.color = vertexArray[vertexID].color;
    return  out;
}

// Fragment function
fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]] ,
               constant bool *hasNoTexture [[ buffer(AAPLFragmentHasNoTexture) ]]
               )
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    if (*hasNoTexture)  {
        return  float4(in.color,1);
    }
    
    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
    
   
}

