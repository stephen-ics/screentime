# Email Verification Setup Guide

This guide explains how to configure email verification for your ScreenTime app using Supabase.

## 🚨 **Important: Fix Redirect URL**

If you're getting `http://localhost:3000/?code=...` in your verification emails, you need to configure the correct redirect URL in Supabase.

## 🔧 Supabase Configuration

### 1. Enable Email Confirmation

1. Go to your [Supabase Dashboard](https://app.supabase.com)
2. Navigate to **Authentication** → **Settings**
3. Find the **User Signups** section
4. Toggle **Enable email confirmations** to **ON**

### 2. ⚠️ **CRITICAL: Configure Redirect URLs**

**This is the most important step to fix the localhost issue:**

1. Go to **Authentication** → **URL Configuration**
2. **Remove** any localhost URLs from **Redirect URLs**
3. Add your app's URL scheme:
   ```
   screentimeapp://auth/confirm
   ```
4. **Site URL** should also be set to:
   ```
   screentimeapp://
   ```

### 3. Add URL Scheme to Your App

Add this to your `Info.plist` file:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.screentime.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>screentimeapp</string>
        </array>
    </dict>
</array>
```

### 4. Configure Email Templates

1. Go to **Authentication** → **Email Templates**
2. Select **Confirm signup** template
3. Customize the email template with your app branding:

```html
<h2>Welcome to ScreenTime!</h2>
<p>Thanks for signing up! Please click the link below to verify your email address:</p>
<p><a href="{{ .ConfirmationURL }}">Verify Email Address</a></p>
<p>This link will expire in 24 hours.</p>
<p>If you didn't create an account, you can safely ignore this email.</p>
```

### 5. Configure Email Provider (Optional)

For production, configure a custom email provider:

1. Go to **Settings** → **Auth** → **SMTP Settings**
2. Configure your email provider (SendGrid, Mailgun, etc.)
3. Test the email configuration

## 📱 iOS App Configuration

### 1. URL Scheme Setup

Add your URL scheme to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.screentime.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>screentimeapp</string>
        </array>
    </dict>
</array>
```

### 2. Update Supabase Configuration

Update your `SupabaseConfig.plist`:

```xml
<key>redirectURL</key>
<string>screentimeapp://auth/confirm</string>
```

## 🔄 How Email Verification Works

### 1. User Registration Flow

```
1. User fills signup form
2. App calls authService.signUp()
3. Supabase creates user account (unverified)
4. Supabase sends verification email
5. App shows EmailVerificationView
```

### 2. Email Verification Flow

```
1. User clicks link in email
2. iOS opens app with verification URL
3. App processes URL in onOpenURL handler
4. App calls authService.handleEmailVerification()
5. User is authenticated and redirected to dashboard
```

### 3. Verification States

- **Verified**: User clicked email link, can access app
- **Pending**: User created account, must verify email
- **Failed**: Verification link expired or invalid

## 🧪 Testing Email Verification

### Development Testing

1. Use a real email address you can access
2. Create account in app
3. Check email for verification link
4. Click link to verify
5. Confirm app authenticates user

### Email Template Testing

1. Go to **Authentication** → **Users**
2. Find test user
3. Click **Send Email Confirmation**
4. Check email formatting and links

## 🔍 Troubleshooting

### Common Issues

**Email not received:**
- Check spam/junk folder
- Verify email provider configuration
- Check Supabase logs in dashboard

**Verification link not working:**
- Verify URL scheme is correctly configured
- Check redirect URL in Supabase settings
- Ensure app handles URLs properly

**User can't sign in after verification:**
- Check RLS policies allow verified users
- Verify profile creation trigger works
- Check authentication state management

### Debug Logging

Enable debug logging to troubleshoot:

```swift
// In SupabaseAuthService
logger.info(.auth, "📧 Email verification status: \(isVerified)")
logger.info(.auth, "🔗 Processing verification URL: \(url)")
```

## 📋 Checklist

- [ ] Email confirmation enabled in Supabase
- [ ] Email template customized
- [ ] Redirect URLs configured
- [ ] URL scheme added to Info.plist
- [ ] App handles incoming URLs
- [ ] EmailVerificationView implemented
- [ ] Testing completed with real email
- [ ] Production email provider configured (for live app)

## 🚀 Production Considerations

### Security
- Use HTTPS redirect URLs in production
- Implement rate limiting for resend requests
- Monitor for email verification abuse

### User Experience
- Clear instructions in verification emails
- Helpful error messages for failed verification
- Option to resend verification email
- Graceful handling of expired links

### Monitoring
- Track email delivery rates
- Monitor verification conversion rates
- Log verification failures for debugging

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Templates Guide](https://supabase.com/docs/guides/auth/auth-email-templates)
- [iOS URL Schemes Documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app) 