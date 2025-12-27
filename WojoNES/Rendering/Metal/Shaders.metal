#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                              texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    return texture.sample(textureSampler, in.texCoord);
}


kernel void copyPixels(
    device uint8_t *pixelBuffer [[buffer(0)]],
    texture2d<float, access::write> outputTexture [[texture(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    uint offset = (gid.y * outputTexture.get_width() + gid.x) * 4;
    float4 pixel = float4(
        pixelBuffer[offset] / 255.0,
        pixelBuffer[offset + 1] / 255.0,
        pixelBuffer[offset + 2] / 255.0,
        pixelBuffer[offset + 3] / 255.0
    );
    
    outputTexture.write(pixel, gid);
}

