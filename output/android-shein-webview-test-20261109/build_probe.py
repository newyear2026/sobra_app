#!/usr/bin/env python3
"""Build a small dependency-free native test APK using the installed Android SDK."""
from pathlib import Path
import os,subprocess,zipfile

ROOT=Path(__file__).resolve().parent
SDK=Path('/Users/jaewook/Library/Android/sdk')
TOOLS=SDK/'build-tools/35.0.0'
JDK=Path('/Applications/Android Studio.app/Contents/jbr/Contents/Home')
ANDROID=SDK/'platforms/android-35/android.jar'
OUT=ROOT/'build'
for d in (OUT,OUT/'classes',OUT/'dex'): d.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,JAVA_HOME=str(JDK))
def run(args,cwd=ROOT): subprocess.run([str(a) for a in args],cwd=cwd,env=env,check=True)
run([JDK/'bin/javac','-source','8','-target','8','-classpath',ANDROID,'-d',OUT/'classes',ROOT/'src/com/sobrita/sheinprobe/ProbeActivity.java'])
with zipfile.ZipFile(OUT/'classes.jar','w') as z:
    for f in (OUT/'classes').rglob('*.class'): z.write(f,f.relative_to(OUT/'classes'))
run([TOOLS/'d8','--min-api','24','--lib',ANDROID,'--output',OUT/'dex',OUT/'classes.jar'])
run([TOOLS/'aapt','package','-f','-M',ROOT/'AndroidManifest.xml','-I',ANDROID,'-A',ROOT/'assets','-F',OUT/'unsigned.apk'])
with zipfile.ZipFile(OUT/'unsigned.apk','a') as z:z.write(OUT/'dex/classes.dex','classes.dex')
run([TOOLS/'zipalign','-f','4',OUT/'unsigned.apk',OUT/'aligned.apk'])
key=OUT/'probe-debug.keystore'
if not key.exists():run([JDK/'bin/keytool','-genkeypair','-keystore',key,'-storepass','android','-keypass','android','-alias','probe','-keyalg','RSA','-keysize','2048','-validity','3650','-dname','CN=Sobrita Local Test,OU=Debug,O=Local,C=MX'])
apk=ROOT/'sobrita-shein-probe-debug.apk'
run([TOOLS/'apksigner','sign','--ks',key,'--ks-pass','pass:android','--key-pass','pass:android','--out',apk,OUT/'aligned.apk'])
run([TOOLS/'apksigner','verify',apk])
print('Built',apk,'bytes=',apk.stat().st_size)
