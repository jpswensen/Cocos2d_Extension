//
//  HSVColorPicker.m
//  Geometrix
//
//  Created by John Swensen on 3/12/14.
//  Copyright 2014 Apportable. All rights reserved.
//

#import "HSVColorPicker.h"
#import "CCNode_Private.h"

#import "MainScene.h"
#import "GeometrixSettings.h"

@implementation HSVColorPicker

@synthesize pushingNode=_pushingNode;

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    self.exclusiveTouch = YES;
    
    CGSize winSize = [CCDirector sharedDirector].viewSize;
    float width = 200;
    float height = 200;
    
    _hsvWheel = [[CCRenderTexture alloc] initWithWidth:width height:height pixelFormat:CCTexturePixelFormat_RGBA8888];
    _hsvWheel.position = ccp(width/2,height/2);
    [self setupRenderHSVWheel];
    
    // the sizeMultiplier is used for retina
    float rtSizeMultiplier = 1;
    if( [CCDirector sharedDirector].contentScaleFactor == 2){
        rtSizeMultiplier = 2;
    }
    rtWidthPixels = (width * rtSizeMultiplier);   // size of rt in px. double for retina
    rtHeightPixels = (height * rtSizeMultiplier); // size of rt in px. double for retina
    
    _rtBuffer = (ccColor4B*)malloc(sizeof(ccColor4B) * rtWidthPixels * rtHeightPixels);
    [_hsvWheel beginWithClear:0 g:0 b:0 a:0];
    [_hsvWheel visit];
    glReadPixels(0, 0, rtWidthPixels, rtHeightPixels, GL_RGBA, GL_UNSIGNED_BYTE, _rtBuffer);
    [_hsvWheel end];
    
    _hsvWheel.position = ccp(winSize.width/2,winSize.height/2);
    
    [self addChild:_hsvWheel];
    
    
    
    ccColor4B backgroundColorStart = [GeometrixSettings sharedSingleton].backgroundColor;
    ccColor4B backgroundColorEnd = backgroundColorStart;
    backgroundColorEnd.r-=20.0;
    backgroundColorEnd.g-=20.0;
    backgroundColorEnd.b-=20.0;
    
    _background.startColor = [CCColor colorWithCcColor4b:backgroundColorStart];
    _background.endColor = [CCColor colorWithCcColor4b:backgroundColorEnd];
    
    
    ccColor4B player1Color = [GeometrixSettings sharedSingleton].player1Color;
    ccColor4F hsvPlayer1 = [HSVColorPicker RGBtoHSV:player1Color];
    if (isnan(hsvPlayer1.r) ||
        hsvPlayer1.g < 0.1 || isnan(hsvPlayer1.g) ||
        hsvPlayer1.b < 0.1 || isnan(hsvPlayer1.b))
    {
        hsvPlayer1.r = 0.0;
        hsvPlayer1.g = 1.0;
        hsvPlayer1.b = 1.0;
    }
    float player1Axis = hsvPlayer1.r*M_PI/180.0;
    float player1Dist = hsvPlayer1.g * width/2;

    ccColor4B player2Color = [GeometrixSettings sharedSingleton].player2Color;
    ccColor4F hsvPlayer2 = [HSVColorPicker RGBtoHSV:player2Color];
    if (isnan(hsvPlayer2.r) ||
        hsvPlayer2.g < 0.1 || isnan(hsvPlayer2.g) ||
        hsvPlayer2.b < 0.1 || isnan(hsvPlayer2.b))
    {
        hsvPlayer2.r = M_PI;
        hsvPlayer2.g = 1.0;
        hsvPlayer2.b = 1.0;
    }
    float player2Axis = hsvPlayer2.r*M_PI/180.0;
    float player2Dist = hsvPlayer2.g * width/2;
    
    
    float angleStep = 0.01;
    float radius = 10;
    float lineWidth = 2.5;

    _player1DrawNode = [[CCDrawNode alloc] init];
    _player1DrawNode.contentSize = CGSizeMake(2*(radius+lineWidth), 2*(radius+lineWidth));
    _player1DrawNode.position = ccp(winSize.width/2 + player1Dist * cos(player1Axis+M_PI),winSize.height/2 + player1Dist * sin(player1Axis+M_PI));
    [self addChild:_player1DrawNode z:2];

    for (float angle = angleStep; angle <= 2 * M_PI; angle += angleStep)
    {
        CGPoint pnt1 = ccp(radius*cos(angle-angleStep),radius*sin(angle-angleStep));
        CGPoint pnt2 = ccp(radius*cos(angle),radius*sin(angle));
        [_player1DrawNode drawSegmentFrom:pnt1 to:pnt2 radius:lineWidth color:[CCColor redColor]];
    }
    
    _player2DrawNode = [[CCDrawNode alloc] init];
    _player2DrawNode.contentSize = CGSizeMake(2*(radius+lineWidth), 2*(radius+lineWidth));
    _player2DrawNode.position = ccp(winSize.width/2 + player2Dist * cos(player2Axis+M_PI),winSize.height/2 + player2Dist * sin(player2Axis+M_PI));
    [self addChild:_player2DrawNode z:2];
    
    for (float angle = angleStep; angle <= 2 * M_PI; angle += angleStep)
    {
        CGPoint pnt1 = ccp(radius*cos(angle-angleStep),radius*sin(angle-angleStep));
        CGPoint pnt2 = ccp(radius*cos(angle),radius*sin(angle));
        [_player2DrawNode drawSegmentFrom:pnt1 to:pnt2 radius:lineWidth color:[CCColor blackColor]];
    }

    [self updateColorSchemeFromMarkerPositions];
    
    
}

- (void) setupRenderHSVWheel
{
    CCGLProgram *program = [[CCGLProgram alloc]
                            initWithVertexShaderFilename:@"HSVColorPicker.vsh"fragmentShaderFilename:@"HSVColorPicker.fsh"];
    
    
    _hsvWheel.sprite.shaderProgram = program;
    CHECK_GL_ERROR_DEBUG();
    [_hsvWheel.sprite.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
    [_hsvWheel.sprite.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
    [program addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
    CHECK_GL_ERROR_DEBUG();
    [_hsvWheel.sprite.shaderProgram link];
    CHECK_GL_ERROR_DEBUG();
    [_hsvWheel.sprite.shaderProgram updateUniforms];
    CHECK_GL_ERROR_DEBUG();
    //[_hsvWheel.sprite.texture setAliasTexParameters];
    
    // pass in uniforms
    radiusLoc = glGetUniformLocation(program.program, "u_radius" );
    glUniform1f( radiusLoc, self.contentSize.height/2.0 );
    
}

+ (ccColor4F) RGBtoHSV:(ccColor4B)color
{
    float Rp = (float)color.r/255.0;
    float Gp = (float)color.g/255.0;
    float Bp = (float)color.b/255.0;
    
    float Cmax = max(max(Rp, Gp), Bp);
    float Cmin = min(min(Rp, Gp), Bp);
    float delta = Cmax - Cmin;
    
    float h = 0, s = 0, v = 0;
    if (Cmax == Rp)
    {
        h = 60.0 * fmod((Gp-Bp)/delta, 6.0);
    }
    else if (Cmax == Gp)
    {
        h = 60.0 * ((Bp-Rp)/delta + 2.0);
    }
    else if (Cmax == Bp)
    {
        h = 60.0 * ((Rp-Gp)/delta + 4.0);
    }
    
    if (delta == 0)
    {
        s = 0;
    }
    else
    {
        s = delta/Cmax;
    }
    
    v = Cmax;
    
    return ccc4f(h, s, v, color.a);
}

+ (ccColor4B) HSVtoRGB:(ccColor4F)color
{
    float h = color.r, s = color.g, v = color.b, a=color.a;
    
    float c = v*s;
    float x = c * (1 - fabs( fmod(h / 60.0,2.0) - 1));
    float m = v - c;
    
    float Rp = 0, Gp = 0, Bp = 0;
    if (h>=0 && h<60.0)
    {
        Rp = c;
        Gp = x;
        Bp = 0;
    }
    else if (h>=60.0 && h<120.0)
    {
        Rp = x;
        Gp = c;
        Bp = 0;
    }
    else if (h>=120.0 && h<180.0)
    {
        Rp = 0;
        Gp = c;
        Bp = x;
    }
    else if (h>=180.0 && h<240.0)
    {
        Rp = 0;
        Gp = x;
        Bp = c;
    }
    else if (h>=240.0 && h<300.0)
    {
        Rp = x;
        Gp = 0;
        Bp = c;
    }
    else if (h>=300.0 && h<120.0)
    {
        Rp = c;
        Gp = 0;
        Bp = x;
    }
    
    return ccc4(255.0*(Rp+m), 255.0*(Gp+m), 255.0*(Bp+m), a);
}

- (void) updateColorSchemeFromMarkerPositions
{
    // Get the color of the pixel underneath the touch location
    float scale = [CCDirector sharedDirector].contentScaleFactor;
    
    
    CGPoint player1TexLocation = ccpAdd([_hsvWheel convertToNodeSpaceAR:_player1DrawNode.position], ccp(0.5*_hsvWheel.contentSize.width,0.5*_hsvWheel.contentSize.height));
    player1TexLocation = ccpCompOp(player1TexLocation, roundf);
    int player1Idx = (scale*(int)player1TexLocation.y*rtWidthPixels) + scale*(int)player1TexLocation.x;
    //NSLog(@"player1Idx:%d  (%f,%f)", player1Idx, player1TexLocation.x, player1TexLocation.y);
    [_player1PrimaryColor setColor:[CCColor colorWithCcColor4b:_rtBuffer[player1Idx]]];
    
    CGPoint player2TexLocation = ccpAdd([_hsvWheel convertToNodeSpaceAR:_player2DrawNode.position], ccp(0.5*_hsvWheel.contentSize.width,0.5*_hsvWheel.contentSize.height));
    player2TexLocation = ccpCompOp(player2TexLocation, roundf);
    int player2Idx = (scale*player2TexLocation.y*rtWidthPixels) + scale*player2TexLocation.x;
    [_player2PrimaryColor setColor:[CCColor colorWithCcColor4b:_rtBuffer[player2Idx]]];


}

#define THRESH_INNER 30.0
#define THRESH_OUTER 99.0
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    float distPlayer1 = ccpDistance(touch.locationInWorld, _player1DrawNode.position);
    float distPlayer2 = ccpDistance(touch.locationInWorld, _player2DrawNode.position);
    
    float minDist = min(distPlayer1,distPlayer2);

    if (minDist == distPlayer1)
    {
        _mode = COLORPICK_MODE_PLAYER1ANGLE;
        
        float dist = ccpDistance(touch.locationInWorld, _hsvWheel.position);
        if ( dist > THRESH_INNER && dist < THRESH_OUTER) {
            
            // Update the positions of the
            CGPoint v = ccpSub(touch.locationInWorld, _hsvWheel.position);
            float angle = atan2(v.y,v.x);
            float majorAxis = angle;
            
            //_backgroundDrawNode.position = ccp(_hsvWheel.position.x + dist * cos(majorAxis),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis));
            _player1DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis),
                                               _hsvWheel.position.y + dist * sin(majorAxis));
            //_player2DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis-_angleFromMajorAxis+M_PI),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis-_angleFromMajorAxis+M_PI));
            
        }
    }
    else if (minDist == distPlayer2)
    {
        _mode = COLORPICK_MODE_PLAYER2ANGLE;
        
        float dist = ccpDistance(touch.locationInWorld, _hsvWheel.position);
        if ( dist > THRESH_INNER && dist < THRESH_OUTER) {
            
            // Update the positions of the
            CGPoint v = ccpSub(touch.locationInWorld, _hsvWheel.position);
            float angle = atan2(v.y,v.x);
            float majorAxis = angle;
            
            //_backgroundDrawNode.position = ccp(_hsvWheel.position.x + dist * cos(majorAxis),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis));
            //_player1DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis+_angleFromMajorAxis+M_PI),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis+_angleFromMajorAxis+M_PI));
            _player2DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis),
                                               _hsvWheel.position.y + dist * sin(majorAxis));
        }
    }
    
    [self updateColorSchemeFromMarkerPositions];
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{

    if (_mode == COLORPICK_MODE_PLAYER1ANGLE)
    {
        float dist = ccpDistance(touch.locationInWorld, _hsvWheel.position);
        if ( dist > THRESH_INNER && dist < THRESH_OUTER) {
            
            // Update the positions of the
            CGPoint v = ccpSub(touch.locationInWorld, _hsvWheel.position);
            float angle = atan2(v.y,v.x);
            float majorAxis = angle;
            
            //_backgroundDrawNode.position = ccp(_hsvWheel.position.x + dist * cos(majorAxis),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis));
            _player1DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis),
                                               _hsvWheel.position.y + dist * sin(majorAxis));
            //_player2DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis-_angleFromMajorAxis+M_PI),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis-_angleFromMajorAxis+M_PI));
            
        }
    }
    else if (_mode == COLORPICK_MODE_PLAYER2ANGLE)
    {
        float dist = ccpDistance(touch.locationInWorld, _hsvWheel.position);
        if ( dist > THRESH_INNER && dist < THRESH_OUTER) {
            
            // Update the positions of the
            CGPoint v = ccpSub(touch.locationInWorld, _hsvWheel.position);
            float angle = atan2(v.y,v.x);
            float majorAxis = angle;
            
            //_backgroundDrawNode.position = ccp(_hsvWheel.position.x + dist * cos(majorAxis),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis));
            //_player1DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis+_angleFromMajorAxis+M_PI),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis+_angleFromMajorAxis+M_PI));
            _player2DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis),
                                               _hsvWheel.position.y + dist * sin(majorAxis));
        }
    }
    [self updateColorSchemeFromMarkerPositions];
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_mode == COLORPICK_MODE_PLAYER1ANGLE)
    {
        float dist = ccpDistance(touch.locationInWorld, _hsvWheel.position);
        if ( dist > THRESH_INNER && dist < THRESH_OUTER) {
            
            // Update the positions of the
            CGPoint v = ccpSub(touch.locationInWorld, _hsvWheel.position);
            float angle = atan2(v.y,v.x);
            float majorAxis = angle;
            
            //_backgroundDrawNode.position = ccp(_hsvWheel.position.x + dist * cos(majorAxis),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis));
            _player1DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis),
                                               _hsvWheel.position.y + dist * sin(majorAxis));
            //_player2DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis-_angleFromMajorAxis+M_PI),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis-_angleFromMajorAxis+M_PI));
            
        }
    }
    else if (_mode == COLORPICK_MODE_PLAYER2ANGLE)
    {
        float dist = ccpDistance(touch.locationInWorld, _hsvWheel.position);
        if ( dist > THRESH_INNER && dist < THRESH_OUTER) {
            
            // Update the positions of the
            CGPoint v = ccpSub(touch.locationInWorld, _hsvWheel.position);
            float angle = atan2(v.y,v.x);
            float majorAxis = angle;
            
            //_backgroundDrawNode.position = ccp(_hsvWheel.position.x + dist * cos(majorAxis),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis));
            //_player1DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis+_angleFromMajorAxis+M_PI),
            //                                   _hsvWheel.position.y + dist * sin(majorAxis+_angleFromMajorAxis+M_PI));
            _player2DrawNode.position =    ccp(_hsvWheel.position.x + dist * cos(majorAxis),
                                               _hsvWheel.position.y + dist * sin(majorAxis));
        }
    }
    
    [self updateColorSchemeFromMarkerPositions];
    
    //_background.startColor = [CCColor colorWithCcColor4b:_backgroundPrimaryColor.color.ccColor4b];
    //_background.endColor = [CCColor colorWithCcColor4b:_backgroundPrimaryColor.color.ccColor4b];
}


- (void) setDarkBackground:(id) sender
{
    _background.startColor = [CCColor colorWithRed:90.0/255.0 green:90.0/255.0 blue:90.0/255.0 alpha:255.0];
    _background.endColor = [CCColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:255.0];
}


- (void) setLightBackground:(id) sender
{
    _background.startColor = [CCColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:255.0];
    _background.endColor = [CCColor colorWithRed:215.0/255.0 green:215.0/255.0 blue:215.0/255.0 alpha:255.0];
}



- (void) closeColorPicker:(id) sender
{
    // Set the colors in the GeometrixSettings
    [GeometrixSettings sharedSingleton].backgroundColor = _background.startColor.ccColor4b;
    [GeometrixSettings sharedSingleton].player1Color = _player1PrimaryColor.color.ccColor4b;
    [GeometrixSettings sharedSingleton].player2Color = _player2PrimaryColor.color.ccColor4b;
    [[GeometrixSettings sharedSingleton] saveToUserDefaults];
    
    self.exclusiveTouch = NO;
    
    if (_pushingNode!=nil)
        [_pushingNode setBackgroundColorFromSettings];
    
    //MainScene* ms = (MainScene*)[self.parent getChildByName:@"MainScene" recursively:NO];
    //[ms setBackgroundColorFromSettings];
    //[ms visit];

    
    [[CCDirector sharedDirector] popScene];
    //[[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MainScene"]];
}


@end
