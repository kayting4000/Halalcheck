@echo off
set "JAVA_HOME=C:\Users\KAYTING4K\.Neo4jDesktop2\Cache\runtime\zulu21.44.17-ca-jdk21.0.8-win_x64"
echo Using Java at: %JAVA_HOME%
gradlew.bat signingReport
