#使用方法

if [ ! -d ./IPADir ];
then
mkdir -p IPADir;
fi

#计时
SECONDS=0

#取当前时间字符串添加到文件结尾
now=$(date +"%Y%m%d-%H:%M")

# 获取 setting.plist 文件路径
setting_path=/Users/mecrt/Desktop/DaBao_Demo/Setting.plist

# 项目名称
project_name=$(/usr/libexec/PlistBuddy -c "print project_name" ${setting_path})

# 项目路径 workspace路径
project_path=$(/usr/libexec/PlistBuddy -c "print project_path" ${setting_path})
workspace_path="${project_path}/${project_name}.xcworkspace"

# scheme名称
scheme_name=$(/usr/libexec/PlistBuddy -c "print scheme_name" ${setting_path})

# 项目版本
project_version=$(/usr/libexec/PlistBuddy -c "print project_version" ${setting_path})

# 配置打包样式：Release、AdHoc、Debug
configuration=$(/usr/libexec/PlistBuddy -c "print configuration" ${setting_path})

# 发布地址：蒲公英->PGY，苹果->AppStore
upload_address=$(/usr/libexec/PlistBuddy -c "print upload_address" ${setting_path})

# ipa包名称：项目名+版本号+打包类型
ipa_name=$(/usr/libexec/PlistBuddy -c "print ipa_name" ${setting_path})

# ipa包路径
ipa_path2=$(/usr/libexec/PlistBuddy -c "print ipa_path" ${setting_path})/${now}
ipa_path="${ipa_path2}-V${project_version}-${upload_address}"

# 打包配置plist文件路径
plist_path=$(/usr/libexec/PlistBuddy -c "print plist_path" ${setting_path})

# 编译build路径
archive_path="${ipa_path}/${project_name}.xcarchive"

# 上传到蒲公英设置
user_key=$(/usr/libexec/PlistBuddy -c "print user_key" ${setting_path})
api_key=$(/usr/libexec/PlistBuddy -c "print api_key" ${setting_path})
password=$(/usr/libexec/PlistBuddy -c "print password" ${setting_path})

if [${upload_address} == "AppStore" ];then
configuration="Release"
plist_path=${project_path}/exportAppstore.plist
else
if [ ${configuration} == "Release" ];then
plist_path=${project_path}/exportAppstore.plist
else
plist_path=${project_path}/exportAdHoc.plist
fi
fi

echo '--正在清理工程--'
xcodebuild clean -configuration ${configuration} -quiet  || exit

echo '清理完成-->>>--正在编译工程:'${configuration}
xcodebuild archive -workspace ${workspace_path} -scheme ${scheme_name} \
-configuration ${configuration} \
-archivePath ${archive_path} -quiet  || exit

echo '编译完成-->>>--开始ipa打包'
xcodebuild -exportArchive -archivePath ${archive_path} \
-configuration ${configuration} \
-exportPath ${ipa_path} \
-exportOptionsPlist ${plist_path} \
-quiet || exit

if [ -e ${ipa_path}/${ipa_name}.ipa ]; then
echo '--ipa包已导出--'
open $ipa_path
else
echo '--ipa包导出失败--'
fi
echo '打包ipa完成-->>>--开始发布ipa包'

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

exit 0
