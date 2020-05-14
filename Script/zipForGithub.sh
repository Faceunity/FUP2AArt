 #压缩工程里面的.a文件，为上线github做准备
Faceunity_path=../FUP2A/Faceunity/
FaceUnity_SDK_iOS=${Faceunity_path}FaceUnity-SDK-iOS/
P2A=${Faceunity_path}P2A/
fuai_a=libfuai.a
fuai_a_path=${FaceUnity_SDK_iOS}${fuai_a}
funama_a=libnama.a
funama_a_path=${FaceUnity_SDK_iOS}${funama_a}
p2a_client_a=libp2a_client.a
p2a_client_a_path=${P2A}${p2a_client_a}


#压缩
cd  ${FaceUnity_SDK_iOS}

#从备份获取
mv ${fuai_a%.*}_back.a  $fuai_a
mv ${funama_a%.*}_back.a  $funama_a

zip ${fuai_a%.*}.zip $fuai_a
mv $fuai_a ${fuai_a%.*}_back.a
zip ${funama_a%.*}.zip $funama_a
mv $funama_a ${funama_a%.*}_back.a
cd -

cd ${P2A}

mv ${p2a_client_a%.*}_back.a  $p2a_client_a
zip ${p2a_client_a%.*}.zip $p2a_client_a
mv $p2a_client_a ${p2a_client_a%.*}_back.a

