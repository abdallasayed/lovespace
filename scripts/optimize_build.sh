#!/bin/bash
echo "⚡ تحسين سرعة البناء مع MultiDex..."

cd android

# إعداد productFlavors للبناء السريع في التطوير
cat >> app/build.gradle << 'EOL'

android {
    flavorDimensions "mode"
    productFlavors {
        dev {
            dimension "mode"
            minSdkVersion 21  # لتفعيل dex preprocessing
        }
        prod {
            dimension "mode"
            minSdkVersion 21  # أو أي قيمة تريدها للإنتاج
        }
    }
}
EOL

echo "✅ تم تحسين إعدادات البناء"
