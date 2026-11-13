#include "EGL/egl.h"
#include <Metal/Metal.h>
#include <OpenGLES/EAGL.h>
#include <SDL2/SDL_keyboard.h>
#include <SDL2/SDL_syswm.h>
#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

void setPixelFormat(void *layerPtr) {
    CAMetalLayer *metalLayer = (CAMetalLayer *)layerPtr;
    NSLog(@"%lu\n", metalLayer.pixelFormat);
    //metalLayer.pixelFormat = MTLPixelFormatRGBA8Unorm;
    //metalLayer.colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
}

void printPixelFormat(void *layerPtr) {
    CAMetalLayer *metalLayer = (CAMetalLayer *)layerPtr;
    //metalLayer.pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB;
    NSLog(@"%lu\n", metalLayer.pixelFormat);
}

void enableGLMultithreading(void) {
    EAGLContext *context = [EAGLContext currentContext];
    if ([context isMultiThreaded])
        [context setMultiThreaded:NO];
}