//
//  HSVColorPicker.h
//  Geometrix
//
//  Created by John Swensen on 3/12/14.
//  Copyright 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


#import "MainScene.h"

typedef enum ColorPickModeEnum  {
    COLORPICK_MODE_MAJORAXIS = 0,
    COLORPICK_MODE_PLAYER1ANGLE,
    COLORPICK_MODE_PLAYER2ANGLE,
} ColorPickMode_t;

@interface HSVColorPicker : CCNode {
    
    CCNode<TopLevelNode>* _pushingNode;
    
    ColorPickMode_t _mode;
    
    CCNodeGradient* _background;
    
    
    // This defines the angle of the major axis of the color scheme
    //  (1) the tail of this axis defines the background color
    //  (2) the player colors are symmetric about the head of this axis
    //float _majorAxis;
    
    // This defines the angular distance of the first player color from the major axis.
    //  (1) Can be positive or negative
    //  (2) the second player will be symmetric about this axis
    //float _angleFromMajorAxis;
    
    
    CCDrawNode* _player1DrawNode;
    CCNodeColor* _player1PrimaryColor;

    CCDrawNode* _player2DrawNode;
    CCNodeColor* _player2PrimaryColor;
        
    
    CCRenderTexture* _hsvWheel;
    CCSprite* _hsvSprite;
    ccColor4B* _rtBuffer;
    
    GLuint radiusLoc;
    float rtWidthPixels;
    float rtHeightPixels;
    
    
    
}

@property (nonatomic,strong) CCNode<TopLevelNode>* pushingNode;

//- (id)initWithWidth:(float)width height:(float)height;
+ (ccColor4F) RGBtoHSV:(ccColor4B)color;
+ (ccColor4B) HSVtoRGB:(ccColor4F)color;

@end
