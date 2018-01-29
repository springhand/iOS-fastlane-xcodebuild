#!/bin/bash

#计时
SECONDS=0

# 取当前时间字符串添加到文件结尾
now=$(date +"%Y%m%d-%H:%M")

# 获取 Setting.plist 文件路径
setting_path=/Users/mecrt/Desktop/DaBao_Demo/Setting.plist

# 项目名称
project_name=$(/usr/libexec/PlistBuddy -c "print project_name" ${setting_path})

# 项目路径
project_path=$(/usr/libexec/PlistBuddy -c "print project_path" ${setting_path})
workspace_path="${project_path}/${project_name}.xcworkspace"

# scheme名称
scheme=$(/usr/libexec/PlistBuddy -c "print scheme_name" ${setting_path})

# 项目版本
project_version=$(/usr/libexec/PlistBuddy -c "print project_version" ${setting_path})

# 配置打包样式：Release、AdHoc、Debug
configuration=$(/usr/libexec/PlistBuddy -c "print configuration" ${setting_path})

# 发布地址：蒲公英->PGY，苹果->AppStore
upload_address=$(/usr/libexec/PlistBuddy -c "print upload_address" ${setting_path})

# ipa包名称
ipa_name=$(/usr/libexec/PlistBuddy -c "print ipa_name" ${setting_path})

# ipa包路径
ipa_path2=$(/usr/libexec/PlistBuddy -c "print ipa_path" ${setting_path})/${now}
ipa_path="${ipa_path2}-V${project_version}-${upload_address}"

# 配置plist路径    
plist_path=${project_path}/exportAdHoc.plist

# 指定输出归档文件地址
archive_path="${ipa_path}/${project_name}.xcarchive"

# 上传到蒲公英设置
user_key=$(/usr/libexec/PlistBuddy -c "print user_key" ${setting_path})
api_key=$(/usr/libexec/PlistBuddy -c "print api_key" ${setting_path})
password=$(/usr/libexec/PlistBuddy -c "print password" ${setting_path})

if [ ${upload_address} == "AppStore" ];then
configuration="Release"
export_method='app-store'
plist_path=${project_path}/exportAppstore.plist
else 
if [ ${configuration} == "Release" ];then
export_method='app-store'
plist_path=${project_path}/exportAppstore.plist
else
export_method='ad-hoc'
plist_path=${project_path}/exportDebug.plist
fi
fi

# 输出设定的变量值
#echo "----ipa_name->>>"${ipa_name}

# 先清空前一次build
echo "--开始编译打包--"${ipa_name}
fastlane gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --archive_path ${archive_path} --export_method ${export_method} --output_directory ${ipa_path} --output_name ${ipa_name} --export_options ${plist_path}

echo "--开始上传-->>>--"${upload_address}
if [ ${upload_address} == "AppStore" ];then
# 验证并上传到App Store，上传AppStore的参数设置等需要再研究查找核对。
altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
"$altoolPath" --validate-app -f ${ipa_path}/${ipa_name}.ipa -u iosmanager@system.ifohoo.com -p zxF515?611 -t ios --output-format xml
"$altoolPath" --upload-app -f ${ipa_path}/${ipa_name}.ipa -u iosmanager@system.ifohoo.com -p zxF515?611 -t ios --output-format xml
else
curl -F "file=@${ipa_path}/${ipa_name}.ipa" -F "uKey=${user_key}" -F "_api_key=${api_key}" -F "password=${password}" https://www.pgyer.com/apiv1/app/upload
fi

# 输出总用时
echo "执行耗时: ${SECONDS}秒"
