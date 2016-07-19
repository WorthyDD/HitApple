//
//  GameScene.m
//  HitApple
//
//  Created by 武淅 段 on 16/4/28.
//  Copyright (c) 2016年 武淅 段. All rights reserved.
//

#import "GameScene.h"
#import "GameOverScene.h"
#import <AVFoundation/AVFoundation.h>

#define RETRY_TIMES 3

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

@property (nonatomic) SKSpriteNode *ball;
@property (nonatomic) SKSpriteNode *apple;
@property (nonatomic) UIButton *resetButton;
@property (nonatomic) NSMutableArray *toolNodeArray;
/**
 *  剩余的机会
 */
@property (nonatomic, assign) NSInteger chances;

@property (nonatomic) AVAudioPlayer *player1;
@property (nonatomic) AVAudioPlayer *player2;
@property (nonatomic) NSMutableArray *players;
@end

@implementation GameScene

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    [self initScene];
    _chances = RETRY_TIMES;
//    _rank = 6;
    [self resetScene];
}


- (void) initScene
{
    SKSpriteNode *ball = [[SKSpriteNode alloc]initWithImageNamed:@"ball"];
    ball.size = CGSizeMake(40, 40);
    ball.position = CGPointMake(self.size.width/2, 20);
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:20];
    ball.physicsBody.dynamic = NO;
    ball.physicsBody.restitution = 0.6;
    ball.physicsBody.density = 0.3;
    ball.physicsBody.categoryBitMask = kBallCategory;
    ball.physicsBody.contactTestBitMask = kAppleCategory|kWallCategory;
    
    SKSpriteNode *apple = [[SKSpriteNode alloc]initWithImageNamed:@"apple"];
    apple.size = CGSizeMake(40, 40);
    apple.position = CGPointMake(self.size.width/2, self.size.height-20);
    apple.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:20];
    apple.physicsBody.dynamic = NO;
    apple.physicsBody.restitution = 0.6;
    apple.physicsBody.density = 0.6;
    apple.physicsBody.categoryBitMask = kAppleCategory;
    apple.physicsBody.contactTestBitMask = kBallCategory|kWallCategory;
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
    
    [self setBackgroundColor:[UIColor colorWithRed:237/255.0 green:250/255.0 blue:221/255.0 alpha:1.0]];
    
    _toolNodeArray = [[NSMutableArray alloc]init];
    _rank = 9;
}

- (void) didTapResetButton : (id)sender
{
    self.rank = 9;
    [self resetScene];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */

    NSLog(@"----%f", _ball.position.y);
    if(_rank == 9){
        if(_ball.position.y <= 25 || (_ball.position.y>self.size.height-160+10 && _ball.position.y < self.size.height-160+80)){
        }
        else{
            return;
        }
    }
    else if(_ball.position.y>25){
        return;
    }
    if(_chances<=0){
        //Game over
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        GameOverScene *gameOver = [[GameOverScene alloc]initWithSize:self.size won:NO];
        [self.view presentScene:gameOver transition:reveal];
        return;
    }
    _chances--;
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
    
    if((contact.bodyA.categoryBitMask|contact.bodyB.categoryBitMask) == (kBallCategory|kAppleCategory)){
        
        _apple.physicsBody.dynamic = YES;
        for(SKNode *node in _toolNodeArray){
            //道具崩溃
            node.physicsBody.dynamic = YES;
        }
        self.physicsWorld.contactDelegate = nil;
        __weak typeof(self) weakSelf = self;
        SKAction *wait = [SKAction waitForDuration:5.0];
        [self runAction:wait completion:^{
            
            [weakSelf nextLevel];
        
        }];
        
        //过关
        //    self.rank++;
        //    [self resetScene];
    }
    else if((contact.bodyA.categoryBitMask|contact.bodyB.categoryBitMask) == (kBallCategory|kWallCategory)){
 //
    }
    
    
}


- (void) resetScene
{
    if(_toolNodeArray.count>0){
        for(SKNode *node in _toolNodeArray){
            [node removeFromParent];
        }
        [_toolNodeArray removeAllObjects];
    }
    

    switch (_rank) {
        case 0:{
            
            NSLog(@"\n\nrank 0\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2, self.size.height-20);
            break;
        }
        case 1:{
            NSLog(@"\n\nrank 1\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2, self.size.height-20);
            
            SKSpriteNode *board = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board.size = CGSizeMake(100, 20);
            board.position = CGPointMake(self.size.width/2, self.size.height-40-100);
            board.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board.size];
            board.physicsBody.dynamic = NO;
            board.physicsBody.categoryBitMask = kWallCategory;
            board.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board];
            [_toolNodeArray addObject:board];
            break;
        }
        case 2:{
            NSLog(@"\n\nrank 2\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2, self.size.height-20);
            SKSpriteNode *board = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board.size = CGSizeMake(100, 20);
            board.position = CGPointMake(self.size.width/2, self.size.height-140);
            board.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board.size];
            board.physicsBody.dynamic = NO;
            board.physicsBody.categoryBitMask = kWallCategory;
            board.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board];
            
             _apple.physicsBody.dynamic = YES;
            [_toolNodeArray addObject:board];
            
//            _apple.position = CGPointMake(self.size.width/2, board.position.y+10);
            break;
        }
        case 3:{
            NSLog(@"\n\nrank 3\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2, self.size.height-20);
            
            SKSpriteNode *board = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board.size = CGSizeMake(160, 20);
            board.position = CGPointMake(self.size.width/2, self.size.height-180);
            board.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board.size];
            board.physicsBody.dynamic = NO;
            board.physicsBody.categoryBitMask = kWallCategory;
            board.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board];
            
            _apple.physicsBody.dynamic = YES;
            [_toolNodeArray addObject:board];
            
            break;
        }
        case 4:{
            NSLog(@"\n\nrank 4\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2, self.size.height-20);
            
            SKSpriteNode *board = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board.size = CGSizeMake(100, 20);
            board.position = CGPointMake(self.size.width/2, self.size.height-200);
            board.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board.size];
            board.physicsBody.dynamic = NO;
            board.physicsBody.categoryBitMask = kWallCategory;
            board.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board];
            
            SKAction *rotate = [SKAction rotateByAngle:2*M_PI duration:2];
            [board runAction:[SKAction repeatActionForever:rotate]];
            [_toolNodeArray addObject:board];
            break;
        }
        case 5:{
            NSLog(@"\n\nrank 5\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2, self.size.height-20);
            SKSpriteNode *board = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board.size = CGSizeMake(180, 20);
            board.position = CGPointMake(self.size.width/2, self.size.height-240);
            board.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board.size];
            board.physicsBody.dynamic = NO;
            board.physicsBody.categoryBitMask = kWallCategory;
            board.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board];
            
            SKAction *rotate = [SKAction rotateByAngle:2*M_PI duration:2];
            [board runAction:[SKAction repeatActionForever:rotate]];
            [_toolNodeArray addObject:board];
            break;
        }
        case 6:{
            NSLog(@"\n\nrank 6\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width-20, self.size.height-140);
            SKSpriteNode *board = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board.size = CGSizeMake(80, 20);
            board.position = CGPointMake(self.size.width-40, self.size.height-140-20-10);
            board.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board.size];
            board.physicsBody.dynamic = NO;
            board.physicsBody.categoryBitMask = kWallCategory;
            board.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board];
            
            [_toolNodeArray addObject:board];
            break;
        }
        case 7:{
            NSLog(@"\n\nrank 7\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width-20, self.size.height-60);
            SKSpriteNode *board = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board.size = CGSizeMake(120, 20);
            board.position = CGPointMake(self.size.width-60, self.size.height-60-20-10);
            board.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board.size];
            board.physicsBody.dynamic = NO;
            board.physicsBody.categoryBitMask = kWallCategory;
            board.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board];
            
            [_toolNodeArray addObject:board];
            break;
        }
        case 8:{
            NSLog(@"\n\nrank 8\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2-20, self.size.height-160+10+20);
            SKSpriteNode *board1 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board1.size = CGSizeMake(100, 20);
            board1.position = CGPointMake(self.size.width/2, self.size.height-160);
            board1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board1.size];
            board1.physicsBody.dynamic = NO;
            board1.physicsBody.categoryBitMask = kWallCategory;
            board1.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board1];
            SKSpriteNode *board2 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board2.size = CGSizeMake(20, 80);
            board2.position = CGPointMake(self.size.width/2-50, self.size.height-160+30);
            board2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board2.size];
            board2.physicsBody.dynamic = NO;
            board2.physicsBody.categoryBitMask = kWallCategory;
            board2.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board2];
            SKSpriteNode *board3 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board3.size = CGSizeMake(20, 80);
            board3.position = CGPointMake(self.size.width/2+50, self.size.height-160+30);
            board3.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board3.size];
            board3.physicsBody.dynamic = NO;
            board3.physicsBody.categoryBitMask = kWallCategory;
            board3.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board3];
            
            [_toolNodeArray addObject:board1];
            [_toolNodeArray addObject:board2];
            [_toolNodeArray addObject:board3];
            break;
        }
        case 9:{
            NSLog(@"\n\nrank 9\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(self.size.width/2-40, self.size.height-160+10+20);
            SKSpriteNode *board1 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board1.size = CGSizeMake(120, 20);
            board1.position = CGPointMake(self.size.width/2, self.size.height-160);
            board1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board1.size];
            board1.physicsBody.dynamic = NO;
            board1.physicsBody.categoryBitMask = kWallCategory;
            board1.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board1];
            SKSpriteNode *board2 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board2.size = CGSizeMake(20, 80);
            board2.position = CGPointMake(self.size.width/2-70, self.size.height-160+30);
            board2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board2.size];
            board2.physicsBody.dynamic = NO;
            board2.physicsBody.categoryBitMask = kWallCategory;
            board2.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board2];
            SKSpriteNode *board3 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board3.size = CGSizeMake(20, 80);
            board3.position = CGPointMake(self.size.width/2+70, self.size.height-160+30);
            board3.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board3.size];
            board3.physicsBody.dynamic = NO;
            board3.physicsBody.categoryBitMask = kWallCategory;
            board3.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board3];
            SKSpriteNode *board4 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board4.size = CGSizeMake(80, 20);
            board4.position = CGPointMake(self.size.width/2-40, self.size.height-160+80);
            board4.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board4.size];
            board4.physicsBody.dynamic = NO;
            board4.physicsBody.categoryBitMask = kWallCategory;
            board4.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board4];
            
            [_toolNodeArray addObject:board1];
            [_toolNodeArray addObject:board2];
            [_toolNodeArray addObject:board3];
            [_toolNodeArray addObject:board4];
            break;
        }
        case 10:{
            NSLog(@"\n\nrank 10\n\n");
            _ball.physicsBody.dynamic = NO;
            _ball.position = CGPointMake(self.size.width/2, 20);
            _apple.physicsBody.dynamic = NO;
            _apple.position = CGPointMake(40, self.size.height-100);
            SKSpriteNode *board1 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board1.size = CGSizeMake(160, 20);
            board1.position = CGPointMake(80, self.size.height-10);
            board1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board1.size];
            board1.physicsBody.dynamic = NO;
            board1.physicsBody.categoryBitMask = kWallCategory;
            board1.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board1];
            SKSpriteNode *board2 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board2.size = CGSizeMake(20, 100);
            board2.position = CGPointMake(10, self.size.height-70);
            board2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board2.size];
            board2.physicsBody.dynamic = NO;
            board2.physicsBody.categoryBitMask = kWallCategory;
            board2.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board2];
            SKSpriteNode *board3 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board3.size = CGSizeMake(100, 20);
            board3.position = CGPointMake(50, self.size.height-130);
            board3.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board3.size];
            board3.physicsBody.dynamic = NO;
            board3.physicsBody.categoryBitMask = kWallCategory;
            board3.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board3];
            SKSpriteNode *board4 = [[SKSpriteNode alloc]initWithImageNamed:@"board"];
            board4.size = CGSizeMake(20, 40);
            board4.position = CGPointMake(90, self.size.height-100);
            board4.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:board4.size];
            board4.physicsBody.dynamic = NO;
            board4.physicsBody.categoryBitMask = kWallCategory;
            board4.physicsBody.contactTestBitMask = 0x0;
            [self addChild:board4];
            
            [_toolNodeArray addObject:board1];
            [_toolNodeArray addObject:board2];
            [_toolNodeArray addObject:board3];
            [_toolNodeArray addObject:board4];
            break;
        }
        default:
            break;
    }
    
    self.physicsWorld.contactDelegate = self;
}


- (void) nextLevel
{
    _rank++;
    SKLabelNode *labelNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    labelNode.text = [NSString stringWithFormat:@"Level %ld",_rank];
    labelNode.fontSize = 40;
    labelNode.position = CGPointMake(self.size.width/2.0, self.size.height/2);
    labelNode.fontColor = [SKColor blackColor];
    [self addChild:labelNode];
    
    SKAction *wait = [SKAction waitForDuration:3.0];
    SKAction *end = [SKAction runBlock:^{
        [labelNode removeFromParent];
        [self resetScene];
    }];
    [labelNode runAction:[SKAction sequence:@[wait,end]]];
     
//    [SKView animateWithDuration:6.0 animations:^{
//        labelNode.fontSize = 40;
//    } completion:^(BOOL finished) {
//        [labelNode removeFromParent];
//        self.rank++;
//        [self resetScene];
//    }];

}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
}


@end
