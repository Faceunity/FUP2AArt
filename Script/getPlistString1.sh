
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
	 img3=`echo $img2'`
      plistString="<string>"$img3"</string>"
    echo $plistString
done

done

