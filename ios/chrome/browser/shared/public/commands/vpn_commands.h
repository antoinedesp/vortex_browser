#ifndef IOS_CHROME_BROWSER_SHARED_PUBLIC_COMMANDS_VPN_COMMANDS_H_
#define IOS_CHROME_BROWSER_SHARED_PUBLIC_COMMANDS_VPN_COMMANDS_H_

@protocol VPNCommands <NSObject>

// Toggles VPN connection state
- (void)toggleVPN;

// Connects to VPN, showing paywall if user is not premium
- (void)connectVPN;

// Disconnects from VPN
- (void)disconnectVPN;

// Shows VPN paywall
- (void)showVPNPaywall;

@end

#endif  // IOS_CHROME_BROWSER_SHARED_PUBLIC_COMMANDS_VPN_COMMANDS_H_
