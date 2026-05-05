//
//  DYYYSettingViewController.m
//  DYYY-Optimized
//

#import "DYYYSettingViewController.h"

@implementation DYYYSettingViewController

+ (void)presentFromViewController:(UIViewController *)viewController {
    DYYYSettingViewController *vc = [[self alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [viewController presentViewController:nav animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DYYY 设置";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
    self.navigationItem.rightBarButtonItem = doneBtn;
}

- (void)doneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
