#!/usr/bin/env bash
set -eu

# for another architectures, check https://github.com/leetal/ios-cmake
declare -a -r platforms=('IOS' 'IOS_SIMULATOR')

declare -r working_dir='.'
declare -r frameworks="$working_dir/../frameworks"
declare -r resources="$working_dir/../resources"

declare -r ios_simulator_arm64_winesscalc_package_dir="package_ios_simulator_arm64"
declare -r ios_simulator_x86_64_winesscalc_package_dir="package_ios_simulator_x86_64"
declare -r ios_simulator_winesscalc_package_dir="package_ios_simulator"

declare -r ios_winesscalc_package_dir="package_ios"



# $1: platform
# $2: prefix
function mv_built_lib() {
    declare -r dst_dir=$frameworks/$2-$1
    if [[ -e $dst_dir ]]; then rm -rf "$dst_dir"; fi
    case $1 in
    'OS64')
        mv Release-iphoneos "$dst_dir"
        ;;
    'MAC' | 'MAC_ARM64' | 'MAC_UNIVERSAL')
        mv Release "$dst_dir"
        ;;
    'SIMULATOR64' | 'SIMULATORARM64')
        mv Release-iphonesimulator "$dst_dir"
        ;;
    *)
        exit 1
        ;;
    esac
}

# ########## ########## ########## ########## ########## ########## ########## #

function prepare() {
    #if [[ -e $working_dir ]]; then rm -rf $working_dir; fi
    mkdir -p $frameworks $resources
    rm -fr  $frameworks/* $resources/* $working_dir/build_witnesscalc_ios* $working_dir/package_ios* \
     $working_dir/depends/gmp/package_*
}

function build_gmp() {
  echo '========== ========== ========== ========== ========== =========='
  echo "initing gmp lib source"
  git submodule init
  git submodule update
  echo '========== ========== ========== ========== ========== =========='
  echo "Building library for gimp for iOS"
  $working_dir/build_gmp.sh ios
  echo '========== ========== ========== ========== ========== =========='
  echo "Building library for gimp for iOS Simulator"
  $working_dir/build_gmp.sh ios_simulator
  
}

function build_witnesscalc() {
  echo '========== ========== ========== ========== ========== =========='
  echo "Building library for witnesscalc for iOS"
  make ios
  ios_winesscalc_build_dir=$working_dir/build_witnesscalc_ios
  mkdir -p $ios_winesscalc_build_dir $ios_winesscalc_package_dir && cd $ios_winesscalc_build_dir
  xcodebuild _LONG_LONG_LIMB=true CIRCUIT_NAME=cncircuit -destination 'generic/platform=iOS' -scheme witnesscalc_cncircuitStatic -project witnesscalc.xcodeproj -configuration Debug
  xcodebuild  _LONG_LONG_LIMB=true CIRCUIT_NAME=cncircuit -destination 'generic/platform=iOS' ARCHS=arm64 -project witnesscalc.xcodeproj  -target install -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED=NO  
  
  cd ../
  
  for arch in "arm64" "x86_64"; do    
    echo '========== ========== ========== ========== ========== =========='
    echo "Building library for witnesscalc for iOS Simulator for "
    make ios_simulator_${arch}
    ios_simulator_witnesscalc_build_dir=$working_dir/build_witnesscalc_ios_simulator_${arch}
    cd $ios_simulator_witnesscalc_build_dir
    xcodebuild ARCHS=${arch}  _LONG_LONG_LIMB=true CIRCUIT_NAME=cncircuit -destination 'generic/platform=iOS Simulator' -sdk iphonesimulator -scheme witnesscalc_cncircuitStatic -project witnesscalc.xcodeproj
    xcodebuild  ARCHS=${arch}  _LONG_LONG_LIMB=true CIRCUIT_NAME=cncircuit -destination 'generic/platform=iOS Simulator' -sdk iphonesimulator -project witnesscalc.xcodeproj  -target install -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED=NO
  
    cd ../
  done
  fat_pkg_dir="${working_dir}/${ios_simulator_winesscalc_package_dir}"
  fat_lib_dir="${fat_pkg_dir}/lib"
  
	mkdir -p "${fat_lib_dir}" 
  
  for lib in "libwitnesscalc_cncircuit.a";
  do
  	lipo "${ios_simulator_arm64_winesscalc_package_dir}/lib/${lib}" "${ios_simulator_x86_64_winesscalc_package_dir}/lib/${lib}" -create -output "${fat_lib_dir}/${lib}"
  	echo "Wrote universal fat library for iPhone Simulator arm64/x86_64 to ${fat_lib_dir}/${lib}"
  done  
	#cp -r "${ios_simulator_arm64_winesscalc_package_dir}/include" "${fat_pkg_dir}"
  
}

function make_framework() {

  xcodebuild -create-xcframework \
      -library $working_dir/$ios_winesscalc_package_dir/lib/libwitnesscalc_cncircuit.a \
      -headers $working_dir/$ios_winesscalc_package_dir/include \
      -library $working_dir/$ios_simulator_winesscalc_package_dir/lib/libwitnesscalc_cncircuit.a \
      -output $frameworks/libwitnesscalc_cncircuit.xcframework    
}

function copy_circuit() {
  cp -f $ios_winesscalc_package_dir/bin/*  $resources/
}
# ########## ########## ########## ########## ########## ########## ########## #

prepare
build_gmp
build_witnesscalc
make_framework
copy_circuit

#open $frameworks

