//
//  TCHeadView.h
//  XPApp
//
//  Created by 唐天成 on 16/7/7.
//  Copyright © 2016年 ShareMerge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XPBaseImageView.h"
#import "XPTastStoreModel.h"
@interface TCHeadView : UIView

+(instancetype)headView;
@property (weak, nonatomic) IBOutlet XPBaseImageView *dashImage;
//虚线
@property (weak, nonatomic) IBOutlet UIImageView *dottedLineImageView;

-(void)setView;
//大包中包小包模型
@property (nonatomic, strong)XPPrivateRoomModel *privateRoomModel;
//businessTag数组
@property (nonatomic, strong)NSArray* businessTag;
//storeTags数组
@property (nonatomic, strong)NSArray* storeTags;

//营业时间Label
@property (weak, nonatomic) IBOutlet UILabel *businessTimeLabel;
//联系电话Label
@property (weak, nonatomic) IBOutlet UILabel *businessTelLabel;
//商家地址Label
@property (weak, nonatomic) IBOutlet UILabel *businessAddLabel;
//平均价格Label
@property (weak, nonatomic) IBOutlet UILabel *averagePriceLabel;

//商家图片视图
@property (weak, nonatomic) IBOutlet XPBaseImageView *storeImageView;

@property (nonatomic, strong)NSString* logoString;


@end
