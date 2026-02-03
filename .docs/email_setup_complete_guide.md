# دليل إعداد Email Verification & Password Reset - ميثاق

## 📧 **خطوات الإعداد في Supabase Dashboard**

### **الخطوة 1️⃣: تفعيل Email Confirmation**

```
1. افتح: https://supabase.com/dashboard/project/YOUR_PROJECT_ID
2. اذهب إلى: Authentication → Providers → Email

3. فعّل:
   ✅ Enable Email Provider
   ✅ Confirm email (مهم جداً!)
   ✅ Secure email change (اختياري - موصى به)

4. اضغط Save
```

---

### **الخطوة 2️⃣: إعداد Redirect URLs**

```
Authentication → URL Configuration

Site URL:
--------
https://mithaqapp.com

Additional Redirect URLs:
------------------------
• mithaq://auth/callback
• mithaq://reset-password
• https://mithaqapp.com
• https://mithaqapp.com/auth/callback
• https://mithaqapp.com/reset-password
• http://localhost:3000 (للتطوير)

⚠️ مهم: اضغط Add URL بعد كل إدخال!
```

---

### **الخطوة 3️⃣: تخصيص Sender Name & Email**

```
Authentication → Email Templates

في الأعلى (Settings):
---------------------
Sender Name: ميثاق
Sender Email: noreply@mithaqapp.com
  (أو: noreply@supabase.io إذا لم يكن لديك Domain مخصص)

اضغط Save
```

---

### **الخطوة 4️⃣: Email Template للتأكيد (Confirm Signup)**

```
Authentication → Email Templates → Confirm signup

Subject Line:
------------
✅ مرحباً بك في ميثاق - تأكيد البريد الإلكتروني

Body (HTML):
-----------
📄 انسخ المحتوى من:
   .docs/email_confirmation_template.html

✅ الصق في خانة Body
✅ اضغط Save
```

---

### **الخطوة 5️⃣: Email Template لإعادة التعيين (Reset Password)**

```
Authentication → Email Templates → Reset password

Subject Line:
------------
🔐 إعادة تعيين كلمة المرور - ميثاق

Body (HTML):
-----------
📄 انسخ المحتوى من:
   .docs/email_password_reset_template.html

✅ الصق في خانة Body
✅ اضغط Save
```

---

### **الخطوة 6️⃣: Email Template للتغيير (Change Email)**

```
Authentication → Email Templates → Change email address

Subject Line:
------------
📧 تأكيد تغيير البريد الإلكتروني - ميثاق

Body (HTML):
-----------
استخدم نفس تصميم Confirmation Template
واستبدل:
- العنوان: "تأكيد تغيير البريد الإلكتروني"
- النص: "تلقينا طلباً لتغيير بريدك الإلكتروني..."
- الزر: "تأكيد البريد الجديد"
```

---

## 🔐 **إعداد Custom Domain (اختياري)**

### **إذا كنت تملك mithaqapp.com:**

```
1. في Supabase Dashboard:
   Settings → Custom SMTP

2. استخدم SMTP provider مثل:
   - SendGrid
   - AWS SES
   - Mailgun

3. أدخل التفاصيل:
   - SMTP Host: smtp.sendgrid.net
   - SMTP Port: 587
   - SMTP Username: apikey
   - SMTP Password: YOUR_SENDGRID_API_KEY
   - From Email: noreply@mithaqapp.com
   - From Name: ميثاق

4. احفظ وارسل Test Email
```

---

## 🧪 **اختبار الـ Flows**

### **اختبار Email Verification:**

```
1. سجل حساب جديد في التطبيق
2. افتح البريد الإلكتروني المستخدم
3. ابحث عن رسالة من "ميثاق"
4. اضغط "تأكيد البريد الإلكتروني"
5. ✅ يجب أن يفتح التطبيق تلقائياً
```

### **اختبار Password Reset:**

```
1. افتح التطبيق → تسجيل الدخول
2. اضغط "نسيت كلمة المرور؟"
3. أدخل بريدك الإلكتروني
4. افتح البريد
5. اضغط "إعادة تعيين كلمة المرور"
6. ✅ يجب أن يفتح التطبيق ويطلب كلمة مرور جديدة
```

---

## 📱 **Deep Links في التطبيق**

### **الـ Links المطلوبة:**

```
1. mithaq://auth/callback
   → للتأكيد بعد Signup

2. mithaq://reset-password
   → لإعادة تعيين كلمة المرور

3. mithaq://change-email
   → لتأكيد البريد الجديد
```

### **في iOS (Info.plist):**

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>mithaq</string>
    </array>
  </dict>
</array>
```

### **في Android (AndroidManifest.xml):**

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="mithaq" />
</intent-filter>
```

---

## ⚠️ **ملاحظات مهمة**

### **1. Email Deliverability:**

```
✅ تحقق من Spam folder دائماً
✅ استخدم Custom SMTP للإنتاج
✅ أضف SPF و DKIM records لـ mithaqapp.com
```

### **2. Security:**

```
✅ الرابط يصلح لمدة 1 ساعة فقط
✅ لا يمكن استخدام نفس الرابط مرتين
✅ يحتاج المستخدم طلب رابط جديد بعد انتهاء المدة
```

### **3. User Experience:**

```
✅ رسائل واضحة بالعربية
✅ تصميم احترافي RTL
✅ تعليمات واضحة
✅ معلومات التواصل في Footer
```

---

## 📊 **مراقبة الإيميلات**

### **في Supabase Dashboard:**

```
Authentication → Users → Email Logs

يمكنك رؤية:
- Email Sent ✅
- Email Delivered ✅
- Email Bounced ❌
- Email Opened 👁️
```

---

## 🆘 **حل المشاكل الشائعة**

### **1. الإيميل لا يصل:**

```
✔️ تحقق من Spam
✔️ تأكد من تفعيل Email Provider
✔️ جرب email آخر
✔️ انتظر 5 دقائق
```

### **2. الرابط لا يعمل:**

```
✔️ تحقق من Redirect URLs
✔️ تأكد من Deep Link setup
✔️ جرب الرابط من Mobile Safari/Chrome
```

### **3. "Rate Limit" Error:**

```
✔️ Supabase يحدد عدد emails/hour
✔️ انتظر ساعة وحاول مجدداً
✔️ استخدم Custom SMTP للإنتاج
```

---

## ✅ **Checklist النهائي**

```
□ Email Provider enabled
□ Confirm email ✅ enabled
□ Redirect URLs configured
□ Email templates customized
□ Sender name = "ميثاق"
□ Deep links tested
□ Password reset tested
□ Email confirmation tested
□ Domain mithaqapp.com added
```

---

**🎉 بعد اتباع هذه الخطوات، سيكون لديك:**

1. ✅ Email verification كامل
2. ✅ Password reset يعمل
3. ✅ Emails احترافية بالعربية
4. ✅ Domain: mithaqapp.com
5. ✅ Deep links جاهزة

---

**📞 للمساعدة:**
- Email: support@mithaqapp.com
- الدعم الفني: داخل التطبيق
