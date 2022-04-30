#!/bin/bash
_pwd=`dirname $(readlink -e "$0")`
pushd ${_pwd} &> /dev/null

dependencies="wayland-devel wayland-egl-devel wayland-protocols-devel systemd-devel libGLESv2-devel rsync"
engine_exec="sfdk engine exec" # SailfishOS with sdfk tool

if [ "$1" == "aurora" ]; then 
    echo "Build for AuroraOS"
    engine_exec="docker exec --user mersdk -w `pwd` aurora-os-build-engine" # AuroraOS docker
else 
    echo "Build for SailfishOS"
    engine_exec="docker exec --user mersdk -w `pwd` sailfish-sdk-build-engine_`whoami`" # SailfishOS 4.4 docker 
    # engine_exec="sfdk engine exec" # SailfishOS with sdfk tool
fi
build_dir="build_rpm"

if [[ "${engine_exec}" == *"aurora"* ]]; then
    build_dir="build_aurora_rpm"
fi

build_root="`pwd`/${build_dir}"

echo "Pack latest git cmmit to an archive: ${build_dir}/SOURCES/harbour-glmark2.tar.gz"
rm -fr ${build_root}/{BUILD,SRPMS}
mkdir -p ${build_root}/SOURCES

git archive --output ${build_root}/SOURCES/harbour-glmark2.tar.gz HEAD

if [[ "${engine_exec}" == *"aurora"* ]]; then
    for each in key cert; do
        if [ -f `pwd`/regular_${each}.pem ]; then 
            echo "Файл ключа regular_${each}.pem найден: OK"
            continue;
        fi
        echo -n "Скачиваем ключ regular_${each}.pem для подписи пактов под АврораОС: "
        curl https://community.omprussia.ru/documentation/files/doc/regular_${each}.pem -o regular_${each}.pem &> /dev/null
        if [ $? -eq 0 ]; then 
            echo "OK"
        else
            echo "FAIL"
            echo "Ошибка скачивания regular_${each}.pem: https://community.omprussia.ru/documentation/files/doc/regular_${each}.pem"
            exit 1
        fi
    done
fi

# echo "Targets: "
sfdk_targets=`${engine_exec} sb2-config -l|grep -v default|grep armv7`
# echo "$sfdk_targets"

for each in ${sfdk_targets}; do
    target_arch=${each##*-}
    echo "Build for '$each' target with '$target_arch' architecture"

    if [ -d ${build_root}/BUILD ]; then 
        rm -fr ${build_root}/BUILD
    fi
    mkdir -p ${build_root}/BUILD

    target="${engine_exec} sb2 -t $each"

    #install deps for current target
    ${target} -R -m sdk-install zypper in -y ${dependencies}
    
    # build RPM for current target
    ${target} rpmbuild --define "_topdir `pwd`/${build_dir}" --define "_arch $target_arch" -ba sailfish/sailfish.spec
    if [ $? -ne 0 ] ; then 
        echo "Build RPM for ${each} : FAIL"
        continue; 
    fi

    # sign RPM packacge 
    if [[ "${engine_exec}" == *"aurora"* ]]; then
        echo -n "Signing RPMs: "
        ${target} rpmsign-external sign --key `pwd`/regular_key.pem --cert `pwd`/regular_cert.pem ${build_root}/RPMS/${target_arch}/harbour-glmark2-1.*
        if [ $? -ne 0 ] ; then 
            echo "FAIL"
            break; 
        fi
        echo "OK"
        echo -n "Validate RPMs: "
        validator_output=`${target} rpm-validator -p regular ${build_root}/RPMS/${target_arch}/harbour-glmark2-1.* 2>&1`
        if [ $? -ne 0 ] ; then 
            echo "FAIL"
            echo "${validator_output}"
            break; 
        fi
        echo "OK"
    elif [[ "${engine_exec}" == "sfdk "* ]] ;then
        echo -n "Validate RPM: "
        sfdk config target=${each}
        sfdk check ${build_root}/RPMS/${target_arch}/harbour-glmark2-1.*
        if [ $? -ne 0 ] ; then 
            echo "FAIL"
            break;
        fi
        echo "OK"
    fi
done

popd &> /dev/null