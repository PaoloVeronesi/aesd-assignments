#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # Clean
    make mrproper
    # Configure
    make ARCH=arm64 defconfig
    # Build
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- Image < /dev/null
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs/{bin,dev,etc,home,lib,lib64,proc,sbin,sys,tmp,usr/bin,usr/lib,usr/sbin}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone https://git.busybox.net/busybox
    cd busybox
    git checkout ${BUSYBOX_VERSION}
else
    cd busybox
fi
# cd ${OUTDIR}/busybox
# make distclean
# make ARCH=arm64 defconfig
# sed -i 's/CONFIG_TC=y/CONFIG_TC=n/' .config
# make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE}
# echo "=== CHECK BUSYBOX ARCH ==="
# file busybox
# make CONFIG_PREFIX=${OUTDIR}/rootfs install
cd ${OUTDIR}/busybox
make distclean 2>/dev/null
make ARCH=arm64 defconfig 2>/dev/null
sed -i 's/CONFIG_TC=y/CONFIG_TC=n/' .config
make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} 2>/dev/null
echo "=== CHECK BUSYBOX ARCH ==="
file busybox
make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install 2>/dev/null
echo "=== AFTER INSTALL ==="
file ${OUTDIR}/rootfs/bin/busybox

# TODO: Make and install busybox
cd ${OUTDIR}/rootfs

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp $SYSROOT/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/ 
cp $SYSROOT/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp $SYSROOT/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp $SYSROOT/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/

# TODO: Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
cd $FINDER_APP_DIR
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
cp writer ${OUTDIR}/rootfs/home

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
mkdir -p ${OUTDIR}/rootfs/home/conf
cp $FINDER_APP_DIR/finder.sh ${OUTDIR}/rootfs/home/
cp $FINDER_APP_DIR/finder-test.sh ${OUTDIR}/rootfs/home/
sed -i 's|\.\./conf/assignment\.txt|conf/assignment.txt|g' ${OUTDIR}/rootfs/home/finder-test.sh
cp $FINDER_APP_DIR/conf/username.txt ${OUTDIR}/rootfs/home/conf/
cp $FINDER_APP_DIR/conf/assignment.txt ${OUTDIR}/rootfs/home/conf/
cp $FINDER_APP_DIR/autorun-qemu.sh ${OUTDIR}/rootfs/home/

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root | gzip > ${OUTDIR}/initramfs.cpio.gz