# Known Issues & Requirements for Production

## 🔴 Backend HTTPS Requirement

### Issue
The PWA is served over HTTPS (required for PWAs), but the backend API runs on HTTP:
```
Current: http://msa.merkuz.com:3636
Needed: https://msa.merkuz.com:3636
```

### Why This Matters
Modern browsers block "mixed content" - HTTPS pages calling HTTP APIs. This is a security feature, not a bug.

### Impact
- ✅ Local features work: Prayer times, Qibla, Calendar (no API needed)
- ❌ API-dependent features fail silently: Login, News feed, Videos, Payments

### Solution
Backend team needs to:
1. Enable HTTPS/SSL on the API server (1 day)
2. Configure CORS headers for web.app domain (1 day)

**Timeline: 2 days, Week 2 of the project**

**Cost: Free SSL via Let's Encrypt**

---

## 🟡 CORS Headers

### What's Needed
Backend must allow requests from:
```
https://alfurkan-a003d.web.app
https://*.web.app
```

### Headers Required
```
Access-Control-Allow-Origin: https://alfurkan-a003d.web.app
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
```

---

## 🟢 What Works Without Backend

These features work offline/locally:
- ✅ Prayer time calculations
- ✅ Qibla direction
- ✅ Hijri calendar
- ✅ App navigation
- ✅ UI/theme switching
- ✅ Previously cached content

---

## For Tomorrow's Demo

### What to Say

"The app loads and core features work. For API-dependent features like login and live content, we need the backend to support HTTPS and CORS headers. This is standard for web apps and takes about 2 days to configure. It's scheduled for Week 2 once we get approval."

### Why This is Actually Good

1. **Shows expertise** - You identified a real production requirement
2. **Sets expectations** - Not overpromising
3. **Highlights offline features** - Prayer times work without internet!
4. **Collaborative** - Backend team needs to support this

---

## Week-by-Week Resolution Plan

**Week 1 (Current):**
- ✅ PWA infrastructure setup
- ✅ Web build working
- ✅ Offline features functional

**Week 2:**
- 🔧 Backend team adds HTTPS + CORS (2 days)
- 🔧 Test API integration (1 day)
- 🔧 Fix any authentication issues (2 days)

**Week 3-6:**
- Continue with UI polish, notifications, testing per original plan

---

## Questions They Might Ask

### "Why didn't you know about this before?"
"HTTPS is standard for production APIs. The mobile app works because native apps don't have mixed content restrictions. Web browsers are more strict for security. This is a known requirement for any web app."

### "How long to fix?"
"Backend team needs 2 days for HTTPS and CORS. Not blocking the project - we continue with UI work in parallel."

### "Can we work around it?"
"Not in production. Development mode has workarounds, but production must use HTTPS for security and PWA requirements."

### "Does this delay the launch?"
"No. Backend work happens in Week 2 while I work on UI in Week 1-2. Parallel tracks."

---

## Technical Details (If They Ask)

### Why HTTP Fails on Web
```
Browser: "This page is HTTPS. That API is HTTP. Blocked for security."
```

PWAs REQUIRE HTTPS. No exceptions. The backend must match.

### Why Mobile Apps Don't Have This Issue
Native apps don't have mixed content restrictions. They can call HTTP APIs (though it's still not recommended for security).

### Why This is Actually Common
Almost every web app launch requires backend HTTPS configuration. This is normal.

---

## Bottom Line

**Not a blocker. Standard production requirement. 2-day backend task in Week 2.**

The demo still works to show:
- App architecture
- Offline capabilities  
- Installation flow
- Responsive design
- Feature navigation

That's enough for approval. Details get sorted in execution.
