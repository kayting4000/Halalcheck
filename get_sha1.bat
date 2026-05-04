@echo off
"C:\Program Files\Java\jdk-26.0.1\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
pause
