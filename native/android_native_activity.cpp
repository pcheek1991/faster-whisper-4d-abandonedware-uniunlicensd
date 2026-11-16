// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
// Direct Android NativeActivity: no intermediary application runtime.
// Visual status only; no speech decoder, microphone or network activity.
#include <android/native_activity.h>
#include <android/native_window.h>
#include <android/log.h>
#include "pentagonal_xor_std_free.h"
#include "stability10d.hpp"
#include "deca_sigma.hpp"
#include "tri_pi.hpp"
#include "coreao_gain.hpp"
#include "coreo_stereo.hpp"
#include "word_bridges.hpp"
#include <cstdint>
#include <cstdlib>

namespace {
constexpr const char* tag="SWE-Diamond";
bool original_kernel_preflight() {
    const Features5 source{0.5,0.5,0.5,0.5,0.5};
    const auto score=swe_pxor_scores5(source);
    double nine[9]{0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5};
    swe::stability10d::Result result{};
    const auto route=swe::deca_sigma::run(2.0);
    const auto tri=swe::tri_pi::inspect(route);
    const auto gain=swe::coreao::rf_gain::apply(1.0);
    const float stereo[4]{1.0f,-2.0f,3.0f,-4.0f};
    swe::coreo_stereo::Quad q{};
    float left=0.0f,right=0.0f;
    return score.xor_score>=0.0 &&
      swe::stability10d::calculate(nine,result) &&
      tri.passed() && gain.passed() &&
      swe::coreo_stereo::forward_at(stereo,2,0,q) &&
      swe::coreo_stereo::reverse_at(q,left,right) &&
      left==stereo[0] && right==stereo[1] &&
      swe::word_bridges::language_count==348 &&
      swe::word_bridges::find("fa")!=nullptr;
}
void render(ANativeActivity*,ANativeWindow* window){
    if(!window)return;
    if(ANativeWindow_setBuffersGeometry(window,0,0,WINDOW_FORMAT_RGBA_8888)!=0)return;
    ANativeWindow_Buffer frame{};
    if(ANativeWindow_lock(window,&frame,nullptr)!=0)return;
    if(frame.bits && frame.width>0 && frame.height>0 && frame.stride>=frame.width){
        auto* pixels=static_cast<std::uint32_t*>(frame.bits);
        const int w=frame.width,h=frame.height,halfW=w/2,halfH=h/2;
        for(int y=0;y<h;++y)for(int x=0;x<w;++x){
            const double dx=halfW?double(std::abs(x-halfW))/halfW:1.0;
            const double dy=halfH?double(std::abs(y-halfH))/halfH:1.0;
            const bool diamond=(dx+dy)<0.8;
            const bool facet=(dx+dy)<0.4;
            pixels[static_cast<std::size_t>(y)*frame.stride+x] =
                facet?0xffd6faffu:diamond?0xff4db4deu:0xff121628u;
        }
    }
    ANativeWindow_unlockAndPost(window);
}
void onWindow(ANativeActivity* activity,ANativeWindow* window) {
    render(activity,window);
}
} // namespace

extern "C" __attribute__((visibility("default")))
void ANativeActivity_onCreate(ANativeActivity* activity,void*,std::size_t){
    if(!activity||!activity->callbacks)return;
    const bool okay=original_kernel_preflight();
    __android_log_print(okay?ANDROID_LOG_INFO:ANDROID_LOG_ERROR,tag,
       "Original C++20 math: %s; synthetic only; no speech recognition",
       okay?"verified":"FAILED");
    if(!okay){ANativeActivity_finish(activity);return;}
    activity->callbacks->onNativeWindowCreated=&onWindow;
    activity->callbacks->onNativeWindowRedrawNeeded=&onWindow;
}
