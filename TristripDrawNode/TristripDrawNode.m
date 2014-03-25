//
//  TristripDrawNode.m
//
//  Created by John Swensen on 3/23/14.
//  Copyright 2014 John Swensen. All rights reserved.
//

#import "TristripDrawNode.h"

// ccVertex2F == CGPoint in 32-bits, but not in 64-bits (OS X)
// that's why the "v2f" functions are needed
static ccVertex2F v2fzero = (ccVertex2F){0,0};

static inline ccVertex2F v2f( float x, float y )
{
	return (ccVertex2F){x,y};
}

/*
static inline ccVertex2F v2fadd( ccVertex2F v0, ccVertex2F v1 )
{
	return v2f( v0.x+v1.x, v0.y+v1.y );
}

static inline ccVertex2F v2fsub( ccVertex2F v0, ccVertex2F v1 )
{
	return v2f( v0.x-v1.x, v0.y-v1.y );
}

static inline ccVertex2F v2fmult( ccVertex2F v, float s )
{
	return v2f( v.x * s, v.y * s );
}

static inline ccVertex2F v2fperp( ccVertex2F p0 )
{
	return v2f( -p0.y, p0.x );
}

static inline ccVertex2F v2fneg( ccVertex2F p0 )
{
	return v2f( -p0.x, - p0.y );
}

static inline float v2fdot(ccVertex2F p0, ccVertex2F p1)
{
	return  p0.x * p1.x + p0.y * p1.y;
}

static inline ccVertex2F v2fforangle( float _a_)
{
	return v2f( cosf(_a_), sinf(_a_) );
}

static inline ccVertex2F v2fnormalize( ccVertex2F p )
{
	CGPoint r = ccpNormalize( ccp(p.x, p.y) );
	return v2f( r.x, r.y);
}
*/

static inline ccVertex2F __v2f(CGPoint v )
{
#ifdef __LP64__
	return v2f(v.x, v.y);
#else
	return * ((ccVertex2F*) &v);
#endif
}

static inline ccTex2F __t(ccVertex2F v )
{
	return *(ccTex2F*)&v;
}

@implementation TristripDrawNode


- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _triLength = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (void)clear
{
    [super clear];

    [_triLength removeAllObjects];
}

-(void)render
{
	if( _dirty ) {
		glBindBuffer(GL_ARRAY_BUFFER, _vbo);
		glBufferData(GL_ARRAY_BUFFER, sizeof(ccV2F_C4B_T2F)*_bufferCapacity, _buffer, GL_STREAM_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		_dirty = NO;
	}
	
	ccGLBindVAO(_vao);

    // Iterate through all the triangle strips and draw them separately so that they are not connected.
    int idx = 0;
    for(int i = 0; i < [_triLength count] ; i++){

        int fanLength = [[_triLength objectAtIndex:i] intValue];
        
        glDrawArrays(GL_TRIANGLE_STRIP, idx, fanLength);
        idx += fanLength;
    }

    
	CC_INCREMENT_GL_DRAWS(1);
	
	CHECK_GL_ERROR();
}

-(void)ensureCapacity:(NSUInteger)count
{
	if(_bufferCount + count > _bufferCapacity){
		_bufferCapacity += MAX(_bufferCapacity, count);
		_buffer = realloc(_buffer, _bufferCapacity*sizeof(ccV2F_C4B_T2F));
        //		NSLog(@"Resized vertex buffer to %d", _bufferCapacity);
	}
}


-(void)drawPolyWithStripPoint:(CGPoint *)verts count:(NSUInteger)count fillColor:(CCColor*)color {
    
    ccColor4B fill = color.ccColor4b;
    
    NSUInteger vertex_count = count;
    [self ensureCapacity:vertex_count];
    
    // Add the length of the new triangle strip to the _triLength list
    [_triLength addObject:[NSNumber numberWithUnsignedInteger:vertex_count]];

    // Add the points of the new triangle strip to the existing vertex buffer. Even though all the
    // triangle strips are in the same buffer, they will be drawn separately.
    ccV2F_C4B_T2F *points = (ccV2F_C4B_T2F*)(_buffer + _bufferCount);
    for(int i=0; i < count; i++){
		ccVertex2F v1 = __v2f( verts[i] );
        *points++ = (ccV2F_C4B_T2F){v1, fill, __t(v2fzero) };
    }
    
    _bufferCount += vertex_count;
    
    _dirty = YES;
}

@end
