 
#是否强制更新资源
fSync=0

sync=0#判断svn是否有更新
if ! [ -d "repo2/.svn" ]
then
echo "checkout repo2"
svn checkout svn://192.168.0.126/repo2
sync=1
else

svn revert -R repo2

rev=`svn info repo2 |grep Revision|awk '{print $2}'`
echo $rev
svn up repo2

rev1=`svn info repo2 |grep Revision|awk '{print $2}'`
echo $rev1
if ! [ ${rev##*=}x = ${rev1##*=}x ]; then
echo "资源更新了"
sync=1
else
echo "资源没有更新"
fi
fi


#解压压缩包
function zip_dir(){
zips=`find $1 | grep zip`
for file in $zips
do
#echo $file
#echo ${file%.*}
rm -rf -d ${file%.*}
unzip -o -j $file -d ${file%.*}
zip_dir ${file%.*}
done
}

#遍历文件夹里的文件
function read_dir(){
for file in `ls $1`
do
if [ -d $1"/"$file ]
then
#echo "路径" $file
read_dir $1"/"$file
else

filename=${file%.*}
ext=${file##*.}
path=$1"/"$file

#忽略jpg文件
if ! [ ${ext##*=}x = "jpg"x ]; then

target_path=`find FUP2A/Faceunity -iname $file`

#echo "++++++" $path
#echo "------" $target_path
if ! [ $target_path ]; then
echo "未找到" $file
else
cp -rf $path $target_path
echo $path
fi
fi
fi
done
}

if [ $sync == 1 ] || [ $fSync == 1 ] ; then
if [ $fSync == 1 ] ; then
echo "已开启强制更新资源（fSync = 1）"
fi
echo "更新资源中...."
read_dir repo2/P2A/Art/bundles
echo "资源更新完成。"
fi

