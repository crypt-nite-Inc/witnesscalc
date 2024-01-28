## Dependencies

You should have installed gcc and cmake

In ubuntu:

```sh
sudo apt install build-essential cmake m4
```

## Compilation

### Preparation
```sh
git submodule init
git submodule update
```

### Compile witnesscalc for x86_64 host machine

```sh
./build_gmp.sh host
make host
```

### Compile witnesscalc for arm64 host machine

```sh
./build_gmp.sh host
make arm64_host
```

### Compile witnesscalc for Android

Install Android NDK from https://developer.android.com/ndk or with help of "SDK Manager" in Android Studio.

Set the value of ANDROID_NDK environment variable to the absolute path of Android NDK root directory.

Examples:

```sh
export ANDROID_NDK=/home/test/Android/Sdk/ndk/23.1.7779620  # NDK is installed by "SDK Manager" in Android Studio.
export ANDROID_NDK=/home/test/android-ndk-r23b              # NDK is installed as a stand-alone package.
```

Compilation for arm64:

```sh
./build_gmp.sh android
make android
```

Compilation for x86_64:

```sh
./build_gmp.sh android_x86_64
make android_x86_64
```

### Compile witnesscalc for iOS

Requirements: Xcode.

1. Run:
    ````sh
    ./build_gmp.sh ios
    make ios
    ````
2. Open generated Xcode project. 
3. Add compilation flag `-D_LONG_LONG_LIMB` to all build targets.
4. Add compilation flag `-DCIRCUIT_NAME=auth`, `-DCIRCUIT_NAME=sig` and `-DCIRCUIT_NAME=mtp` to the respective targets.
5. Compile witnesscalc.

## Updating circuits
1. Compile a circuit with compile-circuit.sh script in circuits repo as usual.
2. Replace existing <circuitname>.cpp and <circuitname>.dat files with generated ones (e.g. auth.cpp & auth.dat).
3. Enclose all the code inside <circuitname>.cpp file with `namespace CIRCUIT_NAME` (do not replace `CIRCUIT_NAME` with the real name, it will be replaced at compilation), like this:
   ```c++
   #include ... 
   #include ... 
   
   namespace CIRCUIT_NAME {
   
   // millions of code lines here
   
   } // namespace
    
   ```

## License

witnesscalc is part of the iden3 project copyright 2022 0KIMS association and published with GPL-3 license. Please check the COPYING file for more details.

## Customizations
Created a new script called build_witnesscalc.sh that will compile a cricuit called cntest. This script also cretes xcframeworks that can be used in IOS projects. Below is the process to build a new circuit

1. Create the curcuit. One example below

````cat <<EOT > YOUR_CIRCUIT_NAME.circom
		pragma circom 2.0.0;

		template Multiplier(n) {
		    signal input a;
		    signal input b;
		    signal output c;

		    signal int[n];

		    int[0] <== a*a + b;
		    for (var i=1; i<n; i++) {
		    int[i] <== int[i-1]*int[i-1] + b;
		    }

		    c <== int[n-1];
		}

		component main = Multiplier(1000);
		EOT
````
2. Compile the circuit for c++

````circom YOUR_CIRCUIT_NAME.circom --c
````
This will create a folder named YOUR_CIRCUIT_NAME_cpp/YOUR_CIRCUIT_NAME.cpp and YOUR_CIRCUIT_NAME_cpp/YOUR_CIRCUIT_NAME.dat files

3. Copy YOUR_CIRCUIT_NAME_cpp/YOUR_CIRCUIT_NAME.cpp and YOUR_CIRCUIT_NAME_cpp/YOUR_CIRCUIT_NAME.dat files to this project's src folder

```` cp YOUR_CIRCUIT_NAME_cpp/YOUR_CIRCUIT_NAME.cpp ./src/
     cp YOUR_CIRCUIT_NAME_cpp/YOUR_CIRCUIT_NAME.dat  ./src/
````
4. Add the namespace directive in YOUR_CIRCUIT_NAME.cpp as detailed in [## Updating circuits]
5. create witnesscalc_<YOUR_CIRCUIT_NAME>.h and .cpp files - refer witnesscalc_cntest.h and witnesscalc_cntest.cpp
6. update src/CMakeLists.txt files to define nee targets for your curcuit. refer to target like witnesscalc_cntest
7. Run build_witnesscalc.sh as below. this will output frameworks and resources  folders at the same level as this projects root

````./build_witnesscalc.sh
````
8. copy the .xcframework and the resources fiels to the ios project that will use the witness calculator. 
