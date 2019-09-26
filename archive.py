import os, time
from datetime import datetime
import requests
import json
from biplist import * 
import smtplib
from smtplib import SMTPException
from email.mime.text import MIMEText
from email.header import Header
from smtplib import SMTP_SSL

project_path = str(os.getcwd())
configration = "Release"
scheme = "PeasNovel"
projectname =  scheme + ".xcodeproj"
archivePath = project_path + "/" + "build" + "/" + scheme + ".xcarchive"
exportOptionPlist = "ExportOptions.plist"
exportPath = project_path
appfile = exportPath + '/' + scheme + '.ipa'
pgyer_key = "c3cb946e784090f5008bd0637f43ee86"
pgyer_url = "https://upload.pgyer.com/apiv1/app/upload"
plistPath = project_path  + "/" + scheme + "/Info.plist"

def clean_project():
    print("start clean:")
    os.system('pwd')
    command = 'xcodebuild clean -scheme ' + scheme + ' -configuration ' + configration + '|| exit'
    os.system(command)
    print('Clean Success')
    os.system('git fetch')
    os.system('git pull || exit')
    print('Git Pull Success')


def build_project():
    print("==============>>> start archive! <<===============")
    os.chdir(project_path)
    isFail = os.system(
        'xcodebuild archive -scheme %s -configuration %s -archivePath %s || exit' % (scheme, configration, archivePath)
    )
    if isFail:
         print("==============>>> Archive Fail! <<==================")
    else:
          print("==============>>> Archive archive! %s <<===============" % (archivePath))
    return isFail
       

def export_archive():
    isFail = os.system("xcodebuild -exportArchive -archivePath %s -exportOptionsPlist %s -exportPath %s -allowProvisioningUpdates|| exit"
                % (archivePath, exportOptionPlist, exportPath))
    if isFail:
        print("Export Fail!")
    else:
         print("Export Success!")
         print('IPA is in: %s' % (exportPath))
    return isFail

def upload_to_payer():
    dowloadAddress = ""
    try:
        print("Start to Upload to Pgyer")
        file = {'file': open(appfile, 'rb')}
        param = {'_api_key': pgyer_key, "uKey": "1da23845c796389332085124cb087f17",}
        print(param)
        req = requests.post(url=pgyer_url, data=param, files=file)
        print(req.json())
        code = req.status_code
        print(code)
        if code == 200:
            print("Upload Success \n")
            print("download address: %s\n" % ('https://www.pgyer.com/' + req.json()["data"]["appShortcutUrl"]))
            dowloadAddress = 'https://www.pgyer.com/' + req.json()["data"]["appShortcutUrl"]
            return dowloadAddress
        else:
            print("Upload Fail \n %s ")
    except Exception as e:
        exit(e)
    return dowloadAddress



def getAppBuildVersion():
    try:
       print(plistPath)
       plist = readPlist(plistPath)
       return plist['CFBundleVersion']
    except e:  
      return 0


def addAppBuildVersion():
    try:
       plist = readPlist(plistPath)
       bulid_num = plist['CFBundleVersion']
       print(bulid_num)
       plist['CFBundleVersion'] = str(int(bulid_num) + 1)
       writePlist(plist, plistPath)
    except Exception as e:
        print(e)



def pushBulidVersion(beforeVersion, currentVersion):
    if currentVersion > beforeVersion:
        os.system('git fetch')
        os.system('git pull')
        os.system('git add -f %s' %(plistPath))
        os.system('git commit -m "Test Bulid %s"' % (str(currentVersion)))
        os.system('git push || exit')
    else:
        print("==============>>> Nothing To Commit <<===============")
# 
def sendEmail(reciever, messageContent):
    messageTile = "update package"
    messgaeContent = messageContent
    hostServer = "smtp.163.com"
    sender = "lieoncx@163.com"
    password = "lieon1992316auth"
    smtp = SMTP_SSL(hostServer)
    smtp.set_debuglevel(1)
    smtp.ehlo(hostServer)
    smtp.login(sender, password)
    message = MIMEText(messgaeContent, "plain", 'utf-8')
    message['Subject'] = Header(messageTile, "utf-8")
    message['From'] = sender
    if len(reciever) > 1:
        message['To'] = ','.join(reciever)
    else:
        message['To'] = reciever[0]
    smtp.sendmail(sender, reciever, message.as_string())
    smtp.quit()


if __name__ == '__main__':
   pre_version = getAppBuildVersion()
   clean_project()
   is_build_false = build_project()
   if is_build_false == False:
       is_export_false = export_archive()
       if is_export_false == False:
               dowloadAddress = upload_to_payer()
               if len(dowloadAddress) > 0:
                   addAppBuildVersion()
                   curent_version = getAppBuildVersion()
                   pushBulidVersion(pre_version, curent_version)
                   print('dowloadAddress: %s' % (dowloadAddress))
                    # sendEmail(["1321693056@qq.com"], 'hello there, The IPA has a update, please check in %s' % (dowloadAddress))



# if __name__ == '__main__':
#     pre_version = getAppBuildVersion()
#     dowloadAddress = upload_to_payer()
#     addAppBuildVersion()
#     curent_version = getAppBuildVersion()
#     pushBulidVersion(pre_version, curent_version)
#     print(pre_version)
#     print(curent_version)
#     print('dowloadAddress-dowloadAddress: %s' % (dowloadAddress))

