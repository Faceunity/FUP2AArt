
#!/bin/bash
#文件名: rename.sh
#用途: 重命名 .jpg 和 .png 文件
BASEDIR=$(dirname "$0")
echo "$BASEDIR"
cd $BASEDIR

    count=1;
    for img in `find $BASEDIR  -iname '*.bundle' -type f -maxdepth 1`
    do
      img=${img#./}
      echo $img
      img1=`echo $img | sed 's/_hair/_hair_q/'`
      echo 1----
      echo $img1
      echo 2----
      
     echo "Renaming $img to $img1"
     mv "$img" "$img1"
     let count++


      #new=pose_danren_${img%.*}.${img##*.}
      #echo "Renaming $img to $new"
      #mv "$img" "$new"
      #let count++
done
