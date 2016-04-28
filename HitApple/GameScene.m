//
//  GameScene.m
//  HitApple
//
//  Created by 武淅 段 on 16/4/28.
//  Copyright (c) 2016年 武淅 段. All rights reserved.
//

#import "GameScene.h"



static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}

static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

// Makes a vector have a length of 1
static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}


static const u_int32_t kBallCategory = 0x1<<0;
static const u_int32_t kAppleCategory = 0x1<<1;
static const u_int32_t kWallCategory = 0x1<<2;
@interface GameScene ()<SKPhysicsContactDelegate>

@property (nonatomic) SKShapeNode *ball;
@property (nonatomic) SKShapeNode *apple;
@property (nonatomic) UIButton *resetButton;
@end

@implementation GameScene

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    [self initScene];
}


- (void) initScene
{
    SKShapeNode *ball = [SKShapeNode shapeNodeWithCircleOfRadius:20];
    [ball setFillColor:[SKColor redColor]];
    ball.position = CGPointMake(self.size.width/2, 20);
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:20];
    ball.physicsBody.dynamic = NO;
    ball.physicsBody.restitution = 0.6;
    ball.physicsBody.density = 0.3;
    ball.physicsBody.categoryBitMask = kBallCategory;
    ball.physicsBody.contactTestBitMask = kAppleCategory;
    
    SKShapeNode *apple = [SKShapeNode shapeNodeWithCircleOfRadius:20];
    [apple setFillColor:[SKColor greenColor]];
    apple.position = CGPointMake(self.size.width/2, self.size.height-20);
    apple.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:20];
    apple.physicsBody.dynamic = NO;
    apple.physicsBody.restitution = 0.6;
    apple.physicsBody.density = 0.6;
    apple.physicsBody.categoryBitMask = kAppleCategory;
    apple.physicsBody.contactTestBitMask = kBallCategory;
    [self addChild:ball];
    [self addChild:apple];
    _ball = ball;
    _apple = apple;
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(20, 50, 50, 20)];
    [button setTitle:@"reset" forState:UIControlStateNormal];
    [button setTintColor:[UIColor darkTextColor]];
    [button addTarget:self action:@selector(didTapResetButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    SKPhysicsBody *ground = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody = ground;
    self.physicsBody.categoryBitMask = kWallCategory;
    self.physicsWorld.contactDelegate = self;

}

- (void) didTapResetButton : (id)sender
{
    _ball.physicsBody.dynamic = NO;
    _ball.position = CGPointMake(self.size.width/2, 20);
    _apple.physicsBody.dynamic = NO;
    _apple.position = CGPointMake(self.size.width/2, self.size.height-20);
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */

    NSLog(@"----%f", _ball.position.y);
    if(_ball.position.y>25){
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    _ball.physicsBody.dynamic = YES;
    
    //方向
    CGPoint offset = rwSub(location, _ball.position);
    //CGPoint direction = rwNormalize(offset);
    //NSLog(@"\n\ndirection----[%f,%f]\n\n", direction.x,direction.y);
    [_ball.physicsBody applyImpulse:CGVectorMake(offset.x/10, offset.y/10)];
    
}


- (void)didBeginContact:(SKPhysicsContact *)contact
{
    NSLog(@"\n\ncollistion\n\n");
    
    _apple.physicsBody.dynamic = YES;
    
    //过关

    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
}

@end
