//
//  TristripDrawNode.h
//
//  Created by John Swensen on 3/23/14.
//  Copyright 2014 John Swensen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface TristripDrawNode : CCDrawNode {
    
    /*! Array to keep track of the lengths of each success triangle strip that is added.
     */
    NSMutableArray* _triLength;
}

/*! Add a triangle strip of vertices to the list of polygon strips to be drawn. In this case, all the vertices
 *  will have the vertex color.
 * @param verts A pointer to an array of vertices of the triangle strip.
 * @param count The number of points in the triangle strip (count-2 triangles).
 * @param color The color to use for the entire polygon.
 */
-(void)drawPolyWithStripPoint:(CGPoint *)verts count:(NSUInteger)count fillColor:(CCColor*)color;

@end
