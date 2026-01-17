#!/bin/bash
echo "🔧 تمكين MultiDex تلقائياً..."

# الانتقال لمجلد Android
cd android

# تحديث build.gradle (app level)
echo "📝 تحديث app/build.gradle..."
cat >> app/build.gradle << 'EOL'

android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
EOL

# تحديث AndroidManifest.xml إذا كان minSdk < 21
echo "📝 تحديث AndroidManifest.xml..."
if [ -f app/src/main/AndroidManifest.xml ]; then
    # التحقق من minSdkVersion
    MIN_SDK=$(grep "minSdkVersion" app/build.gradle | grep -o '[0-9]*' | head -1)
    
    if [ ! -z "$MIN_SDK" ] && [ $MIN_SDK -lt 21 ]; then
        echo "⚠️  minSdkVersion هو $MIN_SDK (< 21)، نحتاج لتعديل AndroidManifest.xml"
        sed -i 's/<application/<application android:name="androidx.multidex.MultiDexApplication"/' app/src/main/AndroidManifest.xml
    fi
fi

echo "✅ تم إعداد MultiDex بنجاح"
