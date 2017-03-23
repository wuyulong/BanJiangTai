//
//  TasteViewController.m
//  XPApp
//
//  Created by Pua on 16/5/12.
//  Copyright © 2016年 ShareMerge. All rights reserved.
//

#import "TasteViewController.h"
#import <MJRefresh/MJRefresh.h>
#import <Foundation/Foundation.h>
#import <XPKit/XPKit.h>
#import "TasteViewModel.h"
#import "UIView+XPEmptyData.h"
#import "TasteMainTBCell.h"
#import "TasteBannerCell.h"
#import "TasteFindViewController.h"
#import "TasteMainModel.h"
#import "TasteDetailViewController.h"
//#import "NavHidden.h"
#import "XPTasteDetailViewController.h"
#import "XPBaseNavigationViewController.h"
//#import "MXNavigationBarManager.h"
//#import "MXNavigationBarManager.h"
#import "XPMotionManager.h"
static NSString *const kMXCellIdentifer = @"kMXCellIdentifer";


@interface TasteViewController ()<UITableViewDataSource,UITableViewDelegate,BMKLocationServiceDelegate,BMKMapViewDelegate,BMKGeoCodeSearchDelegate>
{
    UIView *cuisineView;
    UIView *avgPriceView;
    UIView *atmosphereView;
    UIButton *cuisineShowBtn;
    BOOL cuisineShowBtnSelD;
    BOOL clearButtonSeld;
    UIScrollView *filterScr;
    UIButton *cuisineBtn;
    UIButton *avgPriceBtn;
    UIButton *atmosphereBtn;
    UIView *backgroundView;
    UIImageView *filterBgView;
#pragma mark --map
    BOOL isGeoSearch;
    UILabel *CityLabel;
}
@property (strong, nonatomic) IBOutlet TasteViewModel *TasteVModel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic , strong) BMKLocationService *locService ;
@property (nonatomic , strong) BMKGeoCodeSearch *geocodesearch;
@end

@implementation TasteViewController

-(void)viewWillAppear:(BOOL)animated{
    _locService = [[BMKLocationService alloc]init];//定位功能的初始化
    _locService.delegate = self;//设置代理位self
    //启动LocationService
    [_locService startUserLocationService];//启动定位服务
    _geocodesearch = [[BMKGeoCodeSearch alloc] init];
    //编码服务的初始化(就是获取经纬度,或者获取地理位置服务)
    _geocodesearch.delegate = self;//设置代理为self
    NSLog(@"%f",[XPMotionManager sharedInstance].location.coordinate.latitude);
    [self onClickReverseGeocode];
}
-(void)viewWillDisappear:(BOOL)animated
{
    _locService.delegate = nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView hideEmptySeparators];
    [self createFindView];
    @weakify(self);
    self.TasteVModel.storeName=@"";
    self.TasteVModel.dishName=@"";
    self.TasteVModel.avgPrice=@"";
    self.TasteVModel.storeTag=@"";
    self.TasteVModel.storeType=@"";
    self.TasteVModel.storeArea= @"";
    [self rac_liftSelector:@selector(cleverLoader:) withSignals:RACObserve(self.TasteVModel, executing), nil];
    [self rac_liftSelector:@selector(showToastWithNSError:) withSignals:[[RACObserve(self.TasteVModel, error) ignore:nil] map:^id (id value) {
        @strongify(self);
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
        return value;
    }], nil];
    [[RACObserve(self.TasteVModel, finished)ignore:@(NO)]subscribeNext:^(id x) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }];
    [[RACObserve(self.TasteVModel, list) ignore:nil] subscribeNext:^(id x) {
        @strongify(self);
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
        [self.tableView reloadData];
    }];
    [[RACSignal combineLatest:@[[RACObserve(self.TasteVModel, list) ignore:@(NO)], [RACObserve(self.TasteVModel, finished) ignore:nil]] reduce:^id (NSArray *list, NSNumber *finishd){
        return @([finishd boolValue] && list.count == 0);
    }] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        if([x boolValue]) {
            [self.tableView showEmptyData];
        } else {
            [self.tableView destoryEmptyData];
        }
    }];

    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        @strongify(self);
        [self.TasteVModel.reloadCommand execute:nil];
    }];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        @strongify(self);
        [self.TasteVModel.moreCommand execute:nil];
    }];
    [self.tableView.mj_header beginRefreshing];
    
}
/**
 *  百度地图
 */
-(void)onClickReverseGeocode  //发送反编码请求的.
{
    isGeoSearch = false;
    CLLocationCoordinate2D pt = (CLLocationCoordinate2D){0, 0};//初始化
    if (_locService.userLocation.location.coordinate.longitude== 0
        && _locService.userLocation.location.coordinate.latitude== 0) {
        //如果还没有给pt赋值,那就将当前的经纬度赋值给pt
        pt = (CLLocationCoordinate2D){[XPMotionManager sharedInstance].location.coordinate.latitude,
        [XPMotionManager sharedInstance].location.coordinate.longitude};
    }
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];//初始化反编码请求
    reverseGeocodeSearchOption.reverseGeoPoint = pt;//设置反编码的店为pt
    BOOL flag = [_geocodesearch reverseGeoCode:reverseGeocodeSearchOption];//发送反编码请求.并返回是否成功
    if(flag)
    {
        NSLog(@"反geo检索发送成功");
    }
    else
    {
        NSLog(@"反geo检索发送失败");
    }
    
}
-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == 0) {
        BMKPointAnnotation* item = [[BMKPointAnnotation alloc]init];
        item.coordinate = result.location;
        /**
         *  具体地址
         */
//        item.title = result.address;
//        NSString* showmeg = [[NSString alloc]init];
//        showmeg = [NSString stringWithFormat:@"%@",item.title];
        NSString *cityName = result.addressDetail.city;
        CityLabel.text = cityName;
    }
}
/**
 *  搜索头  筛选按钮
 */
-(void)createFindView
{
    UIImageView* FindBackView = [[UIImageView alloc]init];
    FindBackView.image = [UIImage imageNamed:@"taste_find_background"];
    FindBackView.userInteractionEnabled = YES;
    FindBackView.layer.cornerRadius = 15;
    UIImageView *FindImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"taste_main_find"]];
    [FindBackView addSubview:FindImageView];
    UILabel *textLabel = [[UILabel alloc]init];
    textLabel.text = @"请输入商家或者产品名";
    textLabel.font = [UIFont systemFontOfSize:11];
    textLabel.textColor = RGBA(124, 124, 124, 1);
    [FindBackView addSubview:textLabel];
    [self.view addSubview:FindBackView];
    UIImageView *filterView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"taste_filter_bd"]];
    filterView.userInteractionEnabled = YES;
    filterView.layer.cornerRadius = 15;
    [self.view addSubview:filterView];
    UILabel *filterLbale = [[UILabel alloc]init];
    filterLbale.text = @"筛选";
    filterLbale.font = [UIFont systemFontOfSize:11];
    filterLbale.textColor = RGBA(124, 124, 124, 1);
    [filterView addSubview:filterLbale];
    UIImageView *filterImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"taste_main_fitter"]];
    [filterView addSubview:filterImageView];
    UIImageView *cityImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"taste_filter_bd"]];
    cityImageView.userInteractionEnabled = YES;
    [self.view addSubview:cityImageView];

    CityLabel = [[UILabel alloc]init];
    CityLabel.textColor = [UIColor grayColor];
    CityLabel.backgroundColor = [UIColor clearColor];
    CityLabel.frame = cityImageView.frame;
    CityLabel.font = [UIFont systemFontOfSize:12];
    [cityImageView addSubview:CityLabel];
    [CityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(cityImageView);
    }];
    [cityImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(27);
        make.left.equalTo(self.view.mas_left).with.offset(15);
        make.right.equalTo(FindBackView.mas_left).with.offset(-15);
        make.height.mas_equalTo(30);
    }];
    [FindBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(27);
        make.left.equalTo(cityImageView.mas_right).with.offset(15);
        make.right.equalTo(self.view.mas_right).with.offset(-70);
        make.height.mas_equalTo(30);
    }];
    [FindImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(FindBackView.mas_top).with.offset(8);
        make.left.equalTo(FindBackView.mas_left).with.offset(10);
        make.bottom.equalTo(FindBackView.mas_bottom).with.offset(-8);
    }];
    [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(FindImageView.mas_right).with.offset(10);
        make.centerY.equalTo(FindBackView);
    }];
    [filterView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(27);
        make.height.mas_equalTo(30);
        make.left.equalTo(FindBackView.mas_right).with.offset(5);
        make.right.equalTo(self.view.mas_right).with.offset(-15);
    }];
    [filterLbale mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(filterView);
        make.left.equalTo(filterView.mas_left).with.offset(10);
    }];
    [filterImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(filterView);
        make.left.equalTo(filterLbale.mas_right).with.offset(4);
    }];
    

    TasteFindViewController *tasteFindViewController = [[TasteFindViewController alloc]init];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [FindBackView addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(FindBackView);
    }];
    UIButton *filterbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    [filterView addSubview:filterbutton];
    [filterbutton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(filterView);
    }];
    [[button rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
        [self presentViewController:tasteFindViewController animated:YES completion:nil];
    }];
    [[filterbutton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
        if (filterBgView.hidden==YES) {
            [backgroundView setHidden:NO];
            [filterBgView setHidden:NO];
        }else{
            [self createFilterView];
        }
    }];
    
}
/**
 *  筛选条件
 */
-(void)createFilterView{
    NSArray *cuisineArr = @[@"火锅",@"咖啡/酒吧",@"烧烤/烤串",@"面包甜点",@"小吃快餐",@"自助餐",@"日本菜",@"西餐",@"北京菜",@"韩国料理",@"江浙菜",@"粤菜/港式",@"川菜",@"海鲜",@"清真菜",@"素菜",@"西北菜",@"东南亚菜",@"云贵菜",@"鲁菜",@"湘菜",@"东北菜",@"徽菜",@"香锅烤鱼",@"台湾菜",@"其它菜"];
    NSArray *avgPriceArr = @[@"0-50元",@"50-100元",@"100-150元",@"150-200元",@"200-300元",@"300元以上"];
    NSArray *atmosphereArr = @[@"商务宴请",@"朋友聚餐",@"家庭聚会",@"情侣约会",@"休闲小憩",@"老字号",@"夜猫子宵夜",@"上班族午饭"];
    backgroundView = [[UIView alloc]initWithFrame:self.view.frame];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0.5;
    filterBgView = [[UIImageView alloc]init];
    filterBgView.userInteractionEnabled = YES;
    filterBgView.image = [UIImage imageNamed:@"taste_filter_background"];
//    filterBgView.backgroundColor = [UIColor whiteColor];
    filterBgView.clipsToBounds = YES;
    [backgroundView whenTapped:^{
        [backgroundView removeFromSuperview];
        [filterBgView removeFromSuperview];
    }];
    [self.view addSubview:backgroundView];
    [self.view addSubview:filterBgView];
    [filterBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(77);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-140);
    }];
    filterScr = [[UIScrollView alloc]init];
    filterScr.frame = CGRectMake(0, 10, self.view.frame.size.width, self.view.frame.size.height-160);
    filterScr.contentSize = CGSizeMake(0, 500);
    filterScr.userInteractionEnabled = YES;
    filterScr.clipsToBounds = YES;
    [filterBgView addSubview:filterScr];
    cuisineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 118)];
    UIView *cuisineViewLine = [[UIView alloc]initWithFrame:CGRectMake(10, 116, self.view.frame.size.width-20, 1)];
    cuisineViewLine.backgroundColor = RGBA(203, 205, 206, 1);
    [cuisineView addSubview:cuisineViewLine];
    cuisineView.clipsToBounds = YES;
    [filterScr addSubview:cuisineView];
    cuisineView.userInteractionEnabled = YES;
    UILabel *cuisineLabel = [[UILabel alloc]init];
    cuisineLabel.font = [UIFont systemFontOfSize:13];
    cuisineLabel.text = @"菜系";
    [cuisineView addSubview:cuisineLabel];
    [cuisineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cuisineView.mas_top).with.offset(10);
        make.left.equalTo(cuisineView.mas_left).with.offset(11);
    }];

    for (int i = 0 ; i < 26;  i++) {
        cuisineBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [cuisineBtn setTitleColor:RGBA(75, 76, 76, 1) forState:UIControlStateNormal];
        [cuisineBtn setBackgroundImage:[UIImage imageWithColor:RGBA(238, 249, 232, 1)] forState:UIControlStateSelected];
        [cuisineBtn setTitleColor:RGBA(119, 155, 91, 1) forState:UIControlStateSelected];
            cuisineBtn.frame = CGRectMake(10*(i%4+1)+(i%4)*(self.view.frame.size.width-50)/4, 32+((i/4))*43, (self.view.frame.size.width-50)/4, 33);
            [cuisineBtn setTitle:cuisineArr[i] forState:UIControlStateNormal];
            cuisineBtn.tag = 10075+i;
        [cuisineBtn.layer setBorderColor:RGBA(223, 223, 223, 1).CGColor];
        [cuisineBtn.layer setBorderWidth:1];
            cuisineBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        
            [cuisineBtn addTarget:self action:@selector(cuisineButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            [cuisineView addSubview:cuisineBtn];
    }
    avgPriceView = [[UIView alloc]initWithFrame:CGRectMake(0, cuisineView.frame.size.height, self.view.frame.size.width, 132)];
    UIView *avgPriceViewLine = [[UIView alloc]initWithFrame:CGRectMake(10, 130, self.view.frame.size.width-20, 1)];
    avgPriceViewLine.backgroundColor = RGBA(203, 205, 206, 1);
    [avgPriceView addSubview:avgPriceViewLine];
    avgPriceView.clipsToBounds = YES;
    [filterScr addSubview:avgPriceView];
    UILabel *avgPriceLabel = [[UILabel alloc]init];
    avgPriceLabel.font = [UIFont systemFontOfSize:13];
    avgPriceLabel.text = @"人均消费（元）";
    [avgPriceView addSubview:avgPriceLabel];
    [avgPriceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avgPriceView.mas_top).with.offset(15);
        make.left.equalTo(avgPriceView.mas_left).with.offset(11);
    }];
    for (int i = 0 ; i < 6;  i++) {
            avgPriceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            avgPriceBtn.frame = CGRectMake(10*(i%4+1)+(i%4)*(self.view.frame.size.width-50)/4, 37+((i/4))*43, (self.view.frame.size.width-50)/4, 33);
            [avgPriceBtn setTitle:avgPriceArr[i] forState:UIControlStateNormal];
        [avgPriceBtn setTitleColor:RGBA(75, 76, 76, 1) forState:UIControlStateNormal];
        [avgPriceBtn setBackgroundImage:[UIImage imageWithColor:RGBA(238, 249, 232, 1)] forState:UIControlStateSelected];
        [avgPriceBtn setTitleColor:RGBA(119, 155, 91, 1) forState:UIControlStateSelected];
            avgPriceBtn.tag = 10115+i;
            avgPriceBtn.titleLabel.font = [UIFont systemFontOfSize:13];
            [avgPriceBtn.layer setBorderWidth:1];
        [avgPriceBtn.layer setBorderColor:RGBA(223, 223, 223, 1).CGColor];
            [avgPriceBtn addTarget:self action:@selector(avgPriceButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            [avgPriceView addSubview:avgPriceBtn];
    }
    atmosphereView = [[UIView alloc]initWithFrame:CGRectMake(0, +avgPriceView.frame.size.height+cuisineView.frame.size.height, self.view.frame.size.width, 132)];
    UIView *atmosphereViewLine = [[UIView alloc]initWithFrame:CGRectMake(10, 130, self.view.frame.size.width-20, 1)];
    atmosphereViewLine.backgroundColor = RGBA(203, 205, 206, 1);
    [atmosphereView addSubview:atmosphereViewLine];
    atmosphereView.clipsToBounds = YES;
    [filterScr addSubview:atmosphereView];
    UILabel *atmosphereLabel = [[UILabel alloc]init];
    atmosphereLabel.font = [UIFont systemFontOfSize:13];
    atmosphereLabel.text = @"氛围";
    [atmosphereView addSubview:atmosphereLabel];
    [atmosphereLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(atmosphereView.mas_top).with.offset(15);
        make.left.equalTo(atmosphereView.mas_left).with.offset(11);
    }];
    for (int i = 0 ; i < 8;  i++) {
        atmosphereBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        atmosphereBtn.frame = CGRectMake(10*(i%4+1)+(i%4)*(self.view.frame.size.width-50)/4, 37+((i/4))*43, (self.view.frame.size.width-50)/4, 33);
        [atmosphereBtn setTitle:atmosphereArr[i] forState:UIControlStateNormal];
        [atmosphereBtn setTitleColor:RGBA(75, 76, 76, 1) forState:UIControlStateNormal];
        [atmosphereBtn setBackgroundImage:[UIImage imageWithColor:RGBA(238, 249, 232, 1)] forState:UIControlStateSelected];
        [atmosphereBtn setTitleColor:RGBA(119, 155, 91, 1) forState:UIControlStateSelected];            atmosphereBtn.tag = 10101+i;
            atmosphereBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [atmosphereBtn.layer setBorderColor:RGBA(223, 223, 223, 1).CGColor];
        [atmosphereBtn.layer setBorderWidth:1];
        [atmosphereBtn addTarget:self action:@selector(atmosphereButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [atmosphereView addSubview:atmosphereBtn];
    }
    
    cuisineShowBtnSelD = 0;
    cuisineShowBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cuisineShowBtn.frame = CGRectMake(40+3*(self.view.frame.size.width-50)/4, 75, (self.view.frame.size.width-50)/4, 33);
    cuisineShowBtn.backgroundColor = [UIColor whiteColor];
    [cuisineShowBtn.layer setBorderWidth:1];
    [cuisineShowBtn.layer setBorderColor:RGBA(223, 223, 223, 1).CGColor];
    UILabel *showLabel = [[UILabel alloc]init];
    showLabel.text = @"更多";
    showLabel.textColor = RGBA(83, 150, 243, 1);
    showLabel.font = [UIFont systemFontOfSize:13];
    [cuisineShowBtn addSubview:showLabel];
    UIImageView *showImageView = [[UIImageView alloc]init];
    showImageView.image = [UIImage imageNamed:@"filter_show_down"];
    [cuisineShowBtn addSubview:showImageView];
    [showLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cuisineShowBtn).with.offset(20);
        make.centerY.equalTo(cuisineShowBtn);
    }];
    [showImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(showLabel.mas_right).with.offset(4);
        make.centerY.equalTo(cuisineShowBtn);
    }];
    [cuisineView addSubview:cuisineShowBtn];
    [[cuisineShowBtn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
        if (cuisineShowBtnSelD == 0) {
            cuisineView.frame =CGRectMake(0, 0, self.view.frame.size.width, 353);
            cuisineShowBtn.frame = CGRectMake(40+3*(self.view.frame.size.width-50)/4, 290,(self.view.frame.size.width-50)/4, 33);
            cuisineViewLine.frame = CGRectMake(10, 350, self.view.frame.size.width-20, 1);
            cuisineShowBtn.backgroundColor = [UIColor whiteColor];
            avgPriceView.frame =CGRectMake(0, cuisineView.frame.size.height, self.view.frame.size.width, 132);
            atmosphereView.frame = CGRectMake(0, avgPriceView.frame.size.height+cuisineView.frame.size.height, self.view.frame.size.width, 132);
            cuisineShowBtnSelD=1;
            filterScr.contentSize = CGSizeMake(0, avgPriceView.frame.size.height+cuisineView.frame.size.height+320);
            showImageView.image = [UIImage imageNamed:@"filter_show_up"];
        }else{
            cuisineView.frame =CGRectMake(0, 0, self.view.frame.size.width, 118);
            avgPriceView.frame =CGRectMake(0, cuisineView.frame.size.height, self.view.frame.size.width, 132);
            cuisineViewLine.frame = CGRectMake(10, 116, self.view.frame.size.width-20, 1);
            atmosphereView.frame = CGRectMake(0, avgPriceView.frame.size.height+cuisineView.frame.size.height, self.view.frame.size.width, 132);
            cuisineShowBtn.frame = CGRectMake(40+3*(self.view.frame.size.width-50)/4, 75, (self.view.frame.size.width-50)/4, 33);
            cuisineShowBtnSelD=0;
            avgPriceViewLine.frame =CGRectMake(10, 130, self.view.frame.size.width-20, 1);
            atmosphereViewLine.frame =CGRectMake(10, 130, self.view.frame.size.width-20, 1);

            filterScr.contentSize = CGSizeMake(0, avgPriceView.frame.size.height+cuisineView.frame.size.height+130);
            showImageView.image = [UIImage imageNamed:@"filter_show_down"];
        }
    }];
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearButton setTitle:@"清空" forState:UIControlStateNormal];
    clearButton.backgroundColor = [UIColor whiteColor];
    [clearButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [clearButton.layer setBorderColor:RGBA(223, 223, 223, 1).CGColor];
    [clearButton.layer setBorderWidth:1];
    clearButtonSeld = 0;
    UIButton *sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sureButton setTitle:@"确定" forState:UIControlStateNormal];
    sureButton.backgroundColor = RGBA(105, 178, 48, 1);
    [sureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sureButton.layer setBorderColor:RGBA(223, 223, 223, 1).CGColor];
    [sureButton.layer setBorderWidth:1];
    [filterScr addSubview:clearButton];
    [filterScr addSubview:sureButton];
    [clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(atmosphereView.mas_bottom).with.offset(18);
        make.left.equalTo(filterScr.mas_left).with.offset(11);
        make.right.equalTo(filterScr.mas_centerX).with.offset(-5);
    }];
    [sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(atmosphereView.mas_bottom).with.offset(18);
        make.left.equalTo(clearButton.mas_right).with.offset(11);
        make.right.equalTo(atmosphereView.mas_right).with.offset(-11);
    }];
    @weakify(self);
    [[clearButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
            self.TasteVModel.storeName=@"";
            self.TasteVModel.dishName=@"";
            self.TasteVModel.avgPrice=@"";
            self.TasteVModel.storeTag=@"";
            self.TasteVModel.storeType=@"";
            self.TasteVModel.storeArea= @"";
            [backgroundView removeFromSuperview];
            [filterBgView removeFromSuperview];
            [self createFilterView];
    }];
    [[sureButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
        [backgroundView setHidden:YES];
        [filterBgView setHidden:YES];
        self.TasteVModel.storeName=@"";
        self.TasteVModel.dishName=@"";
        self.TasteVModel.storeArea= @"";
        self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            @strongify(self);
            [[self.TasteVModel.reloadCommand execute:nil]subscribeNext:^(id x) {
                [self.tableView reloadData];
            }];
        }];
        self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            @strongify(self);
            [self.TasteVModel.moreCommand execute:nil];
        }];
        [self.tableView.mj_header beginRefreshing];
    }];

}
-(void)cuisineButtonClick:(UIButton *)sender
{
    if (sender != cuisineBtn) {
        cuisineBtn.selected = NO;
        cuisineBtn = sender;
    }
    self.TasteVModel.storeTag=[NSString stringWithFormat:@"%ld",(long)sender.tag];
    cuisineBtn.selected = YES;

}
-(void)avgPriceButtonClick:(UIButton *)sender
{
    if (sender != avgPriceBtn) {
        avgPriceBtn.selected = NO;
        avgPriceBtn = sender;
    }
    self.TasteVModel.avgPrice=[NSString stringWithFormat:@"%ld",(long)sender.tag];
    avgPriceBtn.selected = YES;
}
-(void)atmosphereButtonClick:(UIButton *)sender
{
    if (sender != atmosphereBtn) {
        atmosphereBtn.selected = NO;
        atmosphereBtn = sender;
    }
    self.TasteVModel.storeType=[NSString stringWithFormat:@"%ld",(long)sender.tag];
    atmosphereBtn.selected = YES;}
#pragma mark - Delegate
#pragma mark - UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(0 == indexPath.row) {
        return tableView.width/2;
    }
    
    return 90;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.TasteVModel.list.count+1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XPBaseTableViewCell *cell = nil;
    if(0 == indexPath.row) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TasteHead" forIndexPath:indexPath];
        if (self.TasteVModel.banners !=0) {
        [(TasteBannerCell *)cell configWithBanner:self.TasteVModel.banners];
        }
        
    }else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TasteCell" forIndexPath:indexPath];
        
        if (self.TasteVModel.list.count>2) {
            [cell bindModel:self.TasteVModel.list[indexPath.row-1]];
        }else{
//            [cell bindModel:self.TasteVModel.list[indexPath.row-3]];
        }
        
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     @weakify(self);
    if(0 == indexPath.row) {
        return;
    }else{
//        if(indexPath.row > 0 && indexPath.row<7){
//        TasteDetailViewController *detailVc = [[TasteDetailViewController alloc]init];
//        detailVc.TModel = self.TasteVModel.list[indexPath.row-1];
//        [self presentViewController:detailVc animated:YES completion:nil];
//        }else{
        
        TasteMainModel* mainModel = self.TasteVModel.list[indexPath.row-1];
        
        XPTasteDetailViewController* tasteDetailViewController = [[XPTasteDetailViewController alloc]init];
        [tasteDetailViewController setModel:[[[XPBaseModel alloc] init] tap:^(XPBaseModel *x) {
                @strongify(self);
//                x.identifier = self.viewModel.model.title;
                x.baseTransfer = @[mainModel.businessId,mainModel.storeId,mainModel.storeLogo,mainModel.storeTags];
            }]];
        XPBaseNavigationViewController* baseNavigationViewController = [[XPBaseNavigationViewController alloc]initWithRootViewController:tasteDetailViewController];
            [self presentViewController:baseNavigationViewController animated:YES completion:nil];
//            [self.navigationController pushViewController:tasteDetailViewController animated:YES];//:baseNavigationViewController animated:YES completion:nil];
//        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
