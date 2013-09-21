//
//  GuideMenuViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/19/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideMenuViewController.h"

@implementation GuideMenuViewController

@synthesize guide = _guide;
@synthesize delegate = _delegate;
@synthesize xml = _xml;
@synthesize tagNames = _tagNames;
@synthesize tagsByTagName = _tagsByTagName;
@synthesize guideDescription = _guideDescription;
@synthesize compiler = _compiler;
@synthesize license = _license;

static int TextCellTextViewTag = 101;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.delegate && !self.xml) {
        self.xml = self.delegate.guideMenuControllerXML;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)tagsForTagName:(NSString *)tagName
{
    return [self.tagsByTagName objectForKey:tagName];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return
        self.tagNames.count + // tags
        1 + // description
        1 + // about
        0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < self.tagNames.count) {
        NSArray *tags = [self.tagsByTagName objectForKey:[self.tagNames objectAtIndex:section]];
        return tags.count;
    } else {
        NSInteger i = section - self.tagNames.count;
        // Description
        if (i == 0) {
            return 1;
        }
        // About
        else {
            return 2;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    static NSString *RightDetailCellIdentifier = @"RightDetailCell";
    static NSString *TextCellIdentifier = @"TextCell";
    NSString *tag = [self tagForIndexPath:indexPath];
    if (tag) {
        cell = [tableView dequeueReusableCellWithIdentifier:RightDetailCellIdentifier forIndexPath:indexPath];
    } else {
        NSInteger i = indexPath.section - self.tagNames.count;
        if (i == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:TextCellIdentifier forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:RightDetailCellIdentifier forIndexPath:indexPath];
        }
    }
    
    if (tag) {
        cell.textLabel.text = tag;
        cell.detailTextLabel.text = @"40";
    } else {
        NSInteger i = indexPath.section - self.tagNames.count;
        // Description
        if (i == 0) {
            UITextView *textView = (UITextView *)[cell viewWithTag:TextCellTextViewTag];
            textView.text = self.guideDescription;
        }
        // About
        else {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Author", nil);
                cell.detailTextLabel.text = self.compiler;
            } else {
                cell.textLabel.text = NSLocalizedString(@"License", nil);
                cell.detailTextLabel.text = self.license;
            }
        }
    }
    [cell setIndentationWidth:60.0];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *tag = [self tagForIndexPath:indexPath];
    if (tag) {
        return 44.0;
    }
    NSInteger i = indexPath.section - self.tagNames.count;
    if (i != 0) return 44.0;
    CGSize constraintSize = CGSizeMake(260.0f, MAXFLOAT);
    CGSize labelSize = [self.guideDescription sizeWithFont:[UIFont systemFontOfSize:15.0]
                                         constrainedToSize:constraintSize
                                             lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height + 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title;
    NSString *tagName = [self.tagNames objectAtIndex:section];
    if (tagName) {
        title = NSLocalizedString(tagName, nil);
    }
    NSInteger i = section - self.tagNames.count;
    if (i == 0) {
        title = NSLocalizedString(@"DESCRIPTION", nil);
    } else {
        title = NSLocalizedString(@"ABOUT", nil);
    }
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    view.backgroundColor = [UIColor darkGrayColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(68, 0, 252, 22)];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.text = title;
    label.font = [UIFont systemFontOfSize:12.0];
    [view addSubview:label];
    return view;
}

- (NSString *)tagForIndexPath:(NSIndexPath *)indexPath
{
    return [[self.tagsByTagName objectForKey:[self.tagNames objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *tagName = [self.tagNames objectAtIndex:section];
//    if (tagName) {
//        return NSLocalizedString(tagName, nil);
//    }
//    NSInteger i = section - self.tagNames.count;
//    // Description
//    if (i == 0) {
//        return NSLocalizedString(@"Description", nil);
//    }
//    // About
//    else {
//        return NSLocalizedString(@"About", nil);
//    }
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (NSString *)guideDescription
{
    if (!_guideDescription) {
        _guideDescription = [[self.xml atXPath:@"//INatGuide/dc:description"] text];
    }
    if (!_guideDescription || _guideDescription.length == 0) _guideDescription = NSLocalizedString(@"No description", nil);
    return _guideDescription;
}

- (NSString *)compiler
{
    if (!_compiler) {
        _compiler = [[self.xml atXPath:@"//INatGuide/eol:agent[@role='compiler']"] text];
    }
    if (!_compiler) {
        NSLocalizedString(@"Unknown", nil);
    }
    return _compiler;
}

- (NSString *)license
{
    if (!_license) {
        NSString *licenseURL = [[self.xml atXPath:@"//INatGuide/dc:license"] text];
        if (licenseURL) {
            NSArray *pieces = [licenseURL componentsSeparatedByString:@"/"];
            if (pieces.count > 2) {
                _license = [[NSString stringWithFormat:@"CC %@", [pieces objectAtIndex:pieces.count - 3]] uppercaseString];
                
            }
        }
    }
    if (!_license) {
        NSLocalizedString(@"None, all rights reserved", nil);
    }
    return _license;
}

@end
