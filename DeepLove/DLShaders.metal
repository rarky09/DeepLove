//
//  DLShaders.metal
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void linear(const device float *inVec [[ buffer(0) ]],
                      device float *outVec [[ buffer(1) ]],
                      device float *weights [[ buffer(2) ]],
                      const device float *bias [[ buffer(3) ]],
                      const device int *params [[ buffer(4) ]],
                      uint id [[ thread_position_in_grid ]]
                      )
{
    thread int in_size = params[0];
    thread int out_size = params[1];
    if (int(id) >= out_size) {
        return;
    }
    
    thread float tmp_sum = 0.0;

    for (int i = 0; i < in_size ; ++i) {
        tmp_sum += weights[in_size * id + i] * inVec[i];
    }
    
    outVec[id] = fmax(tmp_sum + bias[id], 0);
}


kernel void softmax(const device float *inVec [[ buffer(0) ]],
                      device float *outVec [[ buffer(1) ]],
                      uint id [[ thread_position_in_grid ]]
                    )
{
    
    outVec[id] = exp(inVec[id]);
}


kernel void splitchannel(texture2d<float, access::read> intex[[texture(0)]],
                               texture2d_array<float, access::write> outtex[[texture(1)]],
                               uint3 id[[thread_position_in_grid]])
{
    if (id.x >= outtex.get_width() || id.y >= outtex.get_height()) {
        return;
    }
    
    float4 rgba = float4(intex.read(id.xy));
        outtex.write(rgba[id.z], id.xy, id.z);
}


kernel void conv(texture2d_array<float, access::read> intex [[texture(0)]],
                 texture2d_array<float, access::write> outtex [[texture(1)]],
                 texture2d_array<float, access::read> weight_tex [[texture(2)]],
                 texture2d_array<float, access::read> bias_tex [[texture(3)]],
                 const device int *conv_params [[ buffer(4) ]],
                 uint3 id [[thread_position_in_grid]])
{
    if (id.x >= outtex.get_width() || id.y >= outtex.get_height() || id.z >= outtex.get_array_size()) {
        return;
    }

    thread uint2 outtex_pos = id.xy;
    thread int in_channel_size = intex.get_array_size();
    thread uint out_channel_id = id.z;
    thread int weight_width = weight_tex.get_width();
    thread int weight_height = weight_tex.get_height();
    thread int padding = conv_params[0];
    thread int stride = conv_params[1];
    thread uint2 intex_pos = stride * outtex_pos + uint2(padding) ;
    thread float sum_conv = 0.0;

    for (int k = 0; k < in_channel_size; ++k) {
        uint weight_id = in_channel_size * out_channel_id + k;
        for (int i = -padding; i < weight_height - padding ; ++i) {
            for (int j = - padding; j < weight_width - padding; ++j) {
                uint2 conv_pos = uint2(intex_pos.x + j, intex_pos.y + i) ;
                uint2 weight_pos = uint2(padding + j, padding + i) ;
                sum_conv += intex.read(conv_pos, k).x * weight_tex.read(weight_pos, weight_id).x ;
            }
        }
    }
    
    thread float bias = bias_tex.read(outtex_pos, out_channel_id).x;
    outtex.write(fmax(sum_conv + bias,0), outtex_pos, out_channel_id);
}


kernel void maxpool(texture2d_array<float, access::read> intex [[texture(0)]],
                 texture2d_array<float, access::write> outtex [[texture(1)]],
                    const device int *pool_params [[ buffer(2) ]],
                 uint3 id [[thread_position_in_grid]])
{
    if (id.x >= outtex.get_width() || id.y >= outtex.get_height() || id.z >= outtex.get_array_size()) {
        return;
    }
    
    thread uint2 outtex_pos = id.xy;
    thread uint out_channel_id = id.z;
    thread int pool_size = pool_params[0];
    thread int padding = pool_params[1];
    thread int stride = pool_params[2];

    thread float tmp_max = 0.0;
    thread uint2 intex_pos = stride * outtex_pos + uint2(padding);
    
    for (int i = -padding; i < pool_size - padding; ++i) {
        for (int j = - padding; j < pool_size - padding; ++j) {
            uint2 pool_pos = uint2(intex_pos.x + j, intex_pos.y + i);
            tmp_max = fmax(intex.read(pool_pos, out_channel_id).x, tmp_max) ;
        }
    }
    outtex.write(tmp_max, outtex_pos, out_channel_id);
}