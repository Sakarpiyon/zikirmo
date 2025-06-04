@echo off
echo ================================================
echo         ZİKİR MATİK ADMIN KULLANICI OLUŞTURMA
echo ================================================
echo.

echo 1. Admin scripti calistirilacak...
cd /d C:\src\zikirmo_new

echo 2. Dart scripti calistiriliyor...
dart lib\scripts\create_admin_user.dart

echo.
echo 3. Islem tamamlandi.
echo.
echo KULLANIM:
echo Admin Email: admin@zikirmatik.com
echo Admin Sifre: Admin123!
echo.
echo Test Email: test@zikirmatik.com  
echo Test Sifre: Test123!
echo.
pause