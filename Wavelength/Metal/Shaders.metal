#include <metal_stdlib>
using namespace metal;

// MARK: - Compute Shader: Write one spectrogram column

kernel void writeSpectrogramColumn(
    device const float*  amplitudes [[buffer(0)]],
    device const uint*   columnIndex [[buffer(1)]],
    device const float4* colormap [[buffer(2)]],
    texture2d<float, access::write> spectrogram [[texture(0)]],
    uint tid [[thread_position_in_grid]]
) {
    if (tid >= 1024) return;

    float amp = clamp(amplitudes[tid], 0.0f, 1.0f);
    uint lutIndex = uint(amp * 255.0f);
    float4 color = colormap[lutIndex];

    uint col = *columnIndex;
    spectrogram.write(color, uint2(col, tid));
}

// MARK: - Vertex/Fragment Shaders: Render spectrogram to screen

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut spectrogramVertex(uint vid [[vertex_id]]) {
    // Full-screen quad as two triangles
    float2 positions[6] = {
        float2(-1, -1), float2(1, -1), float2(-1, 1),
        float2(-1, 1),  float2(1, -1), float2(1, 1)
    };
    float2 texCoords[6] = {
        float2(0, 1), float2(1, 1), float2(0, 0),
        float2(0, 0), float2(1, 1), float2(1, 0)
    };

    VertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 spectrogramFragment(
    VertexOut in [[stage_in]],
    texture2d<float> spectrogram [[texture(0)]],
    device const uint* writeIdx [[buffer(0)]]
) {
    constexpr sampler s(filter::nearest);

    uint totalCols = spectrogram.get_width();
    uint offset = (*writeIdx + 1) % totalCols;

    // Shift U so oldest column maps to left edge, newest to right
    float rawU = in.texCoord.x;
    uint col = (uint(rawU * float(totalCols)) + offset) % totalCols;
    float u = (float(col) + 0.5f) / float(totalCols);

    return spectrogram.sample(s, float2(u, in.texCoord.y));
}
