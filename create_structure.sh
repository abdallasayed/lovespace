#!/bin/bash

echo "🚀 جاري بناء هيكلية المشروع الاحترافية..."

# 1. إنشاء المجلدات الأساسية (Directories)
mkdir -p lib/core/{config,services,constants,utils}
mkdir -p lib/features/auth/{screens,providers}
mkdir -p lib/features/chat
mkdir -p lib/features/memories
mkdir -p lib/features/music
mkdir -p lib/features/home
mkdir -p lib/features/couple
mkdir -p scripts
mkdir -p .github/workflows

# 2. إنشاء ملفات الـ Core (الملفات الأساسية)
touch lib/core/config/firebase_options.dart
touch lib/core/config/theme.dart
touch lib/core/services/firebase_service.dart
touch lib/core/services/upload_service.dart
touch lib/core/constants/app_colors.dart
touch lib/core/constants/strings.dart
touch lib/core/utils/helpers.dart

# 3. إنشاء ملفات الميزات (Features)
# Auth
touch lib/features/auth/screens/login_screen.dart
touch lib/features/auth/screens/register_screen.dart
touch lib/features/auth/providers/auth_provider.dart

# Chat
touch lib/features/chat/chat_screen.dart
touch lib/features/chat/chat_bubble.dart

# Memories
touch lib/features/memories/memories_screen.dart

# Music
touch lib/features/music/music_screen.dart

# Home
touch lib/features/home/home_screen.dart

# Couple (الربط والبحث)
touch lib/features/couple/link_partner_screen.dart
touch lib/features/couple/waiting_screen.dart

# 4. الملفات الرئيسية
touch lib/app.dart

echo "✅ تم إنشاء الهيكلية بنجاح!"
echo "📁 يمكنك الآن رؤية المجلدات الجديدة داخل lib/"

