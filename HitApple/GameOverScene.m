//
//  GameOverScene.m
//  HitApple
//
//  Created by 武淅 段 on 16/7/19.
//  Copyright © 2016年 武淅 段. All rights reserved.
//

#import "GameOverScene.h"
#import "GameScene.h"

@interface GameOverScene()

@property (nonatomic, assign) BOOL won;

@end

@implementation GameOverScene

- (instancetype)initWithSize : (CGSize )size won : (BOOL)won
{
    if(self = [super initWithSize:size]){
        self.won = won;
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        NSString *message;
        if(won){
            message = @"You Won!";
        }
        else{
            message = @"You Lose!";
        }
        
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        label.text = message;
        label.fontSize = 40;
        label.fontColor = [SKColor blackColor];
        label.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:label];
        
        [self runAction:[SKAction sequence:@[
                                             [SKAction waitForDuration:3.0],
                                             [SKAction runBlock:^{
            SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
            GameScene *game = [[GameScene alloc]initWithSize:self.size];
            [self.view presentScene:game transition:reveal];
            }]
        ]]];
    }
    return self;
}

@end
