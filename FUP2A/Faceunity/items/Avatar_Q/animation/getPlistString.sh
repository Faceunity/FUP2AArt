
#!/bin/bash
#文件名: rename.sh
#用途: 重命名 .jpg 和 .png 文件
BASEDIR=$(dirname "$0")
echo "$BASEDIR"
cd $BASEDIR
for subDir in `find $BASEDIR  -type d -maxdepth 1`
 do
   echo --------------------------------------------------------------------
    for img in `find $subDir  -iname '*.bundle' -type f -maxdepth 1 | sort`
    do
      img1=${img##*/}
	 img2=${img1%.*}
	 if [[ "$img1" == "ani_"* ]]; then

  	 if [[ "$img2" != "ani_"*"_"* ]]; then
   plistString="<dict>\n<key>gender</key>\n<string>0</string>\n<key>animation</key>\n<string>$img2</string>\n<key>image</key>\n<string>$img2</string>\n</dict>"
   echo $plistString
fi

fi

done

done

