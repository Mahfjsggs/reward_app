# Reward App — نظام النقاط والمكافآت

## الفكرة
المستخدم يشاهد إعلان مكافأة (Rewarded Ad) → السيرفر (Cloud Functions) يتحقق
من صحة المشاهدة ويمنح النقاط → النقاط تُحسب لاحقًا كحصة من ميزانية المكافآت
الشهرية المبنية على الإيرادات الفعلية → المستخدم يطلب سحب المبلغ.

**القاعدة الذهبية:** التطبيق نفسه لا يملك صلاحية تعديل النقاط أو الرصيد
مباشرة. كل عملية حساسة (منح نقاط، خصم عند السحب) تمر عبر Cloud Function
تتحقق من الشروط داخل Firestore Transaction.

## خطوات التشغيل

### 1. المتطلبات
```
flutter pub get
```
أضف أيضًا إلى `pubspec.yaml`:
```yaml
dependencies:
  cloud_functions: ^5.1.0
  google_mobile_ads: ^6.0.0
```

### 2. Firebase
```
firebase login
firebase init firestore functions
```
ثم انسخ محتوى `firestore.rules` إلى ملف القواعد في مشروعك.

### 3. Cloud Functions
```
cd functions
npm install
npm run deploy
```

### 4. AdMob
- استبدل `rewardedAdUnitId` في `lib/services/ad_service.dart` بمعرف
  إعلانك الحقيقي (المعرف الحالي هو معرف اختبار من جوجل).
- في `android/app/src/main/AndroidManifest.xml` أضف داخل `<application>`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```
- بنفس الطريقة لملف iOS `Info.plist` مع `GADApplicationIdentifier`.

## نقاط أمان مهمة قبل الإطلاق
1. **AdMob SSV (Server-Side Verification):** الكود الحالي يتحقق من الوقت
   المنقضي وسقف يومي كخط دفاع أول، لكن للحماية الكاملة من التلاعب يُفضّل
   ربط `grantAdReward` بآلية SSV الرسمية من AdMob بدل الاعتماد فقط على
   استدعاء العميل بعد `onUserEarnedReward`.
2. **مراجعة سياسات Google Play وAdMob** الخاصة بتطبيقات "شاهد واربح" قبل
   النشر — هذه الفئة من التطبيقات لها قيود واضحة يجب الالتزام بها، ومنها
   عدم تحفيز المستخدم على النقر على الإعلانات نفسها.
3. **App Check:** فعّله في Firebase حتى تتأكد أن استدعاءات Cloud Functions
   تأتي من تطبيقك الحقيقي فقط.
4. **قيمة النقطة ليست ثابتة** — تُحسب شهريًا من `rewardPools` بناءً على
   الإيرادات الفعلية المستوردة من AdMob (revenueReports)، وليس برقم مثل
   "1000 نقطة = 5 دولار" مكتوب في الكود.

## الخطوة التالية المقترحة
- Cloud Function مجدولة (scheduled) تقرأ `revenueReports` كل نهاية شهر
  وتحسب `rewardPools` تلقائيًا، ثم توزّع `withdrawableBalance` على
  المستخدمين حسب حصتهم من `totalEligiblePoints`.
- لوحة Admin (Flutter Web أو React) لعرض ومراجعة طلبات السحب.
