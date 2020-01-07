
#!/bin/bash
#文件名: rename.sh
#用途: 重命名 .jpg 和 .png 文件
BASEDIR=$(dirname "$0")
echo "$BASEDIR"
cd $BASEDIR

    count=1;
    for img in `find $BASEDIR  -iname '*.svn' -o -iname '*.png'  -maxdepth 2`
    do
    echo $img
     rm -rf $img
     let count++


      #new=pose_danren_${img%.*}.${img##*.}
      #echo "Renaming $img to $new"
      #mv "$img" "$new"
      #let count++
done
