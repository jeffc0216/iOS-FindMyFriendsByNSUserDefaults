//
//  ViewController.m
//  FindMyFriends
//
//  Created by Jeff Chen on 2016/5/22.
//  Copyright © 2016年 Jeff Chen. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h> //支援地圖
#import <CoreLocation/CoreLocation.h> //支援定位

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate> { //記得storyboard要拉
    CLLocationManager *locationManager;  //記得要先取得使用者授權
    CLLocation * currentLocation;
    MKCoordinateRegion region;
    NSInteger targetIndex;
    NSInteger tracePathIndex;
    NSInteger polylineIndex;
    NSString *latitude;
    NSString *longtitude;
    NSString *recordPathLat;
    NSString *recordPathLon;
    id result;
    NSMutableArray * path;
    MKPolylineRenderer * renderer;
}
@property (weak, nonatomic) IBOutlet MKMapView *mainMapView;
@property (weak, nonatomic) IBOutlet UITextField *friendTextField;
@property (nonatomic) NSMutableArray *myPathLat;
@property (nonatomic) NSMutableArray *myPathLon;
@property (nonatomic) NSMutableArray *pathRecord;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    locationManager = [CLLocationManager new]; //相同於[[CLLocationManager alloc] init];
    path = [[NSMutableArray alloc]init];
    //檢查是否是iOS8之後的版本，否則會當掉
//    if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]){
//        [locationManager requestWhenInUseAuthorization];
//    }
    //檢查是否是iOS8之後的版本 always
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
        //locationManager.allowsBackgroundLocationUpdates = true;
    }

    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    //NSMutableArray * mypathRecordUserDefault = [userDefaults objectForKey:@"pathRecord"];
    //self.pathRecord = [NSMutableArray arrayWithArray:mypathRecordUserDefault];
    NSMutableArray * myPathLatUserDefault = [userDefaults objectForKey:@"myPathLat"];
    self.myPathLat = [NSMutableArray arrayWithArray:myPathLatUserDefault];
    NSMutableArray * myPathLonUserDefault = [userDefaults objectForKey:@"myPathLon"];
    self.myPathLon = [NSMutableArray arrayWithArray:myPathLonUserDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)trackingModeChanged:(UISegmentedControl *)sender {
    targetIndex =sender.selectedSegmentIndex;
    
    switch (targetIndex) {
        case 0:
            _mainMapView.userTrackingMode = MKUserTrackingModeFollow;
            break;
        case 1:
            //_mainMapView.userTrackingMode = MKUserTrackingModeNone;
            _mainMapView.userTrackingMode = MKUserTrackingModeFollow;
            NSLog(@"上傳位置");
            break;
    }
}

#pragma mark - CLLocationManagerDelegate Methods
-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    currentLocation = [locations lastObject];

    //永遠只執行一次
    static dispatch_once_t changeRegionOnceToken;
    dispatch_once(&changeRegionOnceToken, ^{
        //MKCoordinateRegion region = _mainMapView.region;
        region.center = currentLocation.coordinate;
        //縮放比例指定精度為0.01
        region.span.latitudeDelta = 0.01;
        region.span.longitudeDelta = 0.01;
        [_mainMapView setRegion:region animated:true];
    });
    
    [_mainMapView removeAnnotations:[_mainMapView annotations]];
    //顯示從SERVER抓下來的朋友資訊並用大頭針顯示
    [self addFriendsAnnotationOnMap];
    CLLocationCoordinate2D  annotationCoordinate;
    annotationCoordinate =currentLocation.coordinate;
    MKPointAnnotation * annotation=[MKPointAnnotation new];
    annotation.coordinate=annotationCoordinate;
    [_mainMapView addAnnotation:annotation];
    
    double lati = currentLocation.coordinate.latitude;
    double longti = currentLocation.coordinate.longitude;
    latitude = [NSString stringWithFormat:@"%f",lati];
    longtitude = [NSString stringWithFormat:@"%f",longti];
    
    //是否上傳位址
    if (targetIndex==1) {
        [self updateMyLocation];
    }
    [self loadFriendsLocation];
    
    //開啟軌跡紀錄
    if(tracePathIndex == 1){
        NSString * latPath = [NSString stringWithFormat:@"%.6f", currentLocation.coordinate.latitude];
        NSString * lonPath = [NSString stringWithFormat:@"%.6f", currentLocation.coordinate.longitude];
        //存入陣列
        [self.myPathLat addObject:latPath];
        [self.myPathLon addObject:lonPath];
        //存入永久的儲存裡
        [[NSUserDefaults standardUserDefaults] setObject:self.myPathLat forKey:@"myPathLat"];
        [[NSUserDefaults standardUserDefaults] setObject:self.myPathLon forKey:@"myPathLon"];
        //記得同步
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSInteger latIndex = self.myPathLat.count;
        NSLog(@"%li筆紀錄,座標myPathLat:%@", latIndex, self.myPathLat[latIndex-1]);
        NSInteger lonIndex = self.myPathLon.count;
        NSLog(@"%li筆紀錄,座標myPathLat:%@", lonIndex, self.myPathLon[lonIndex-1]);
    }
    
    //清除軌跡紀錄
    if(tracePathIndex == 2){
        [self.myPathLat removeAllObjects];
        [self.myPathLon removeAllObjects];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    //畫出記錄導航
    if(tracePathIndex == 3){
        path=[NSMutableArray new];
        [_mainMapView removeOverlays:[_mainMapView overlays]];
        
        for(int i=0; i<self.myPathLat.count; i++){
            recordPathLat = self.myPathLat[i];
            recordPathLon = self.myPathLon[i];
            CLLocationCoordinate2D recordCoordinate = CLLocationCoordinate2DMake(recordPathLat.doubleValue, recordPathLon.doubleValue);
            [path addObject:[NSValue valueWithMKCoordinate:recordCoordinate]];
            CLLocationCoordinate2D coordinates[path.count];
            
            for (int i=0;i<path.count;i++) {
                coordinates[i] = [[path objectAtIndex:i] MKCoordinateValue];
            }
            
            MKPolyline * polyLine = [MKPolyline polylineWithCoordinates:coordinates count:path.count];
            renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
            renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
            renderer.lineWidth   = 5;
            [_mainMapView addOverlay:polyLine];
        }
    }
    
    //畫出導航路徑
    if(polylineIndex == 1){
        [_mainMapView removeOverlays:[_mainMapView overlays]];
        [self realtimeDraw];
    }
    
    //清除導航
    if(polylineIndex == 2){
        [_mainMapView removeOverlays:[_mainMapView overlays]];
    }

}

-(void)realtimeDraw {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longtitude.doubleValue);
    [path addObject:[NSValue valueWithMKCoordinate:coordinate]];
    CLLocationCoordinate2D coordinates[path.count];
    
    for (int i=0;i<path.count;i++) {
        coordinates[i] = [[path objectAtIndex:i] MKCoordinateValue];
    }

    MKPolyline * polyLine = [MKPolyline polylineWithCoordinates:coordinates count:path.count];
    renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
    renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
    renderer.lineWidth   = 5;
    [_mainMapView addOverlay:polyLine];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    return renderer;
}

#pragma mark - MKMapViewDelegate Method
-(void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

}

-(void)updateMyLocation{
    NSString * urlstring=[NSString stringWithFormat:@"http://class.softarts.cc/FindMyFriends/updateUserLocation.php?GroupName=ap102&UserName=Jeff&Lat=%.6f&Lon=%.6f",currentLocation.coordinate.latitude,currentLocation.coordinate.longitude];
    NSURL * url =[NSURL URLWithString:urlstring];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession * session=[NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task=[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response,NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error:%@",error);
            return;
        }
    }];
    [task resume];
}

-(void)loadFriendsLocation
{
    NSString * urlstring=[NSString stringWithFormat:@"http://class.softarts.cc/FindMyFriends/queryFriendLocations.php?GroupName=ap102"];
    NSURL * url =[NSURL URLWithString:urlstring];
    NSURLSessionConfiguration *config=[NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession * session=[NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task=[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error:%@",error);
            return ;
        }
        result =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    }];
    [task resume];
}

-(void)addFriendsAnnotationOnMap
{
    NSArray * array =[[NSArray alloc]initWithArray:[result objectForKey:@"friends"]];
    
    for (int i=0; i<array.count; i++) {
        CLLocationCoordinate2D friendsCoordinate;
        NSDictionary * friendsDictionary= array[i];
        NSString *friendsLatitude=[friendsDictionary objectForKey:@"lat"];
        NSString *friendsLongitude=[friendsDictionary objectForKey:@"lon"];
        NSString *friendsName=[friendsDictionary objectForKey:@"friendName"];
        friendsCoordinate.latitude=friendsLatitude.floatValue;
        friendsCoordinate.longitude=friendsLongitude.floatValue;
        MKPointAnnotation * friendsAnnotation=[MKPointAnnotation new];
        friendsAnnotation.title=friendsName;
        friendsAnnotation.coordinate=friendsCoordinate;
        
        if([friendsName isEqualToString:@"Jeff"]){
        }else{
            [_mainMapView addAnnotation:friendsAnnotation];
        }
    }
}

- (IBAction)returnMyLocation:(UIButton *)sender {
    region.center =currentLocation.coordinate;
    region.span.latitudeDelta=0.01;
    region.span.longitudeDelta=0.01;
    [_mainMapView setRegion:region animated:true];
    
}

- (IBAction)findFriendLocation:(UIButton *)sender {
    NSString * friendName =self.friendTextField.text;
    NSArray * array =[[NSArray alloc]initWithArray:[result objectForKey:@"friends"]];
    for (int i=0; i<array.count; i++) {
        NSDictionary * tmpDictionary=array[i];
        NSString * name = [tmpDictionary objectForKey:@"friendName"];
        NSString * lat = [tmpDictionary objectForKey:@"lat"];
        NSString * lon = [tmpDictionary objectForKey:@"lon"];
        if ([friendName isEqualToString:name]) {
            region.center.latitude=lat.floatValue;
            region.center.longitude=lon.floatValue;
            region.span.latitudeDelta=0.01;
            region.span.longitudeDelta=0.01;
            [_mainMapView setRegion:region animated:true];
        }
    }
}

//追蹤軌跡路徑
- (IBAction)tracePath:(UISegmentedControl *)sender {
    tracePathIndex =sender.selectedSegmentIndex;
    
    switch (tracePathIndex) {
        case 0:
            break;
        case 1:
            NSLog(@"紀錄移動軌跡");
            break;
        case 2:
            NSLog(@"清除紀錄");
            break;
        case 3:
            NSLog(@"記錄導航");
            break;
    }
}

- (IBAction)polylinePath:(UISegmentedControl *)sender {
    polylineIndex =sender.selectedSegmentIndex;
    
    switch (polylineIndex) {
        case 0:
            path=[NSMutableArray new];
            break;
        case 1:
            NSLog(@"開啟導航軌跡");
            break;
        case 2:
            NSLog(@"清除導航軌跡");
            break;
    }
}

@end
