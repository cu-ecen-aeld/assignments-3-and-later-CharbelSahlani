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

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR} || { echo "Directory setup failed" >&2; exit 1; }

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
    # The mrproper flag deeps clean the kernel build tree, removing the .config file
    # make ARCH=arm64 \
    # CROSS_COMPILE=aarch64-none-linux-gnu-mrproper
    # The defconfig flag represents the default configuration for our "virt" arm dev to use in sim
    make ARCH=arm64 \
    CROSS_COMPILE=aarch64-none-linux-gnu- defconfig

    # build vm linux target, -j"$(nproc)" to run on multiple cpus in parallel => faster build
    # Build a kernel image for booting with QEMU
    make -j"$(nproc)" ARCH=arm64 \
    CROSS_COMPILE=aarch64-none-linux-gnu- all

    # Build any kernel modules
    #make ARCH=arm64 \
    #CROSS_COMPILE=aarch64-none-linux-gnu-modules

    # Build the devicetree
    # make ARCH=arm64 \
    # CROSS_COMPILE=aarch64-none-linux-gnu-dtbs
fi
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"

echo "Adding the Image in outdir"

ROOTFS="${OUTDIR}/rootfs"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${ROOTFS}" ]
then
	echo "Deleting rootfs directory at ${ROOTFS} and starting over"
    sudo rm  -rf ${ROOTFS}
fi

# TODO: Create necessary base directories
mkdir -p rootfs
cd rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox
make distclean
make defconfig
make ARCH=${ARCH} \
CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${ROOTFS} \
ARCH=${ARCH} \
CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
cd "$OUTDIR"
#${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
#${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
# Copy the program interpreter (Dynamic Linker) to rootfs/lib
# Find where your toolchain's sysroot is
SYSROOT=$(aarch64-none-linux-gnu-gcc --print-sysroot)

INTERPRETER=$(${CROSS_COMPILE}readelf -a rootfs/bin/busybox | grep "program interpreter" | awk -F': ' '{print $2}' | tr -d ']')

# Prepend sysroot to get the actual host path
INTERP_HOST="${SYSROOT}${INTERPRETER}"

if [ -n "$INTERPRETER" ] && [ -f "$INTERP_HOST" ]; then
    cp -L "$INTERP_HOST" rootfs/lib/
else
    echo "Error: Interpreter not found or invalid path: $INTERP_HOST" >&2
fi

# Copy the Shared Libraries to rootfs/lib64
SYSROOT=$(${CROSS_COMPILE}gcc --print-sysroot)

${CROSS_COMPILE}readelf -a rootfs/bin/busybox | grep "Shared library" | awk -F'[' '{print $2}' | tr -d ']' | while read -r lib; do
    LIB_PATH=$(find "${SYSROOT}/lib" "${SYSROOT}/lib64" "${SYSROOT}/usr/lib" -name "$lib" 2>/dev/null | head -n 1)
    if [ -n "$LIB_PATH" ]; then
        cp -L "$LIB_PATH" rootfs/lib64/
        echo "Copied $lib to rootfs/lib64"
    else
        echo "Warning: Could not locate library $lib" >&2
    fi
done

# TODO: Make device nodes
sudo mknod -m 666 dev/null c 1 3 || true
sudo mknod -m 600 dev/console c 5 1 || true

# TODO: Clean and build the writer utility
make -C "${FINDER_APP_DIR}" clean
make -C "${FINDER_APP_DIR}" CROSS_COMPILE=${CROSS_COMPILE} CFLAGS="-Wall -Werror -static"

cp "${FINDER_APP_DIR}/writer" "${ROOTFS}/home/writer"

# TODO: Copy the finder related scripts and executables to the /home directory
cp "${FINDER_APP_DIR}/finder.sh" "${ROOTFS}/home/finder.sh"
cp "${FINDER_APP_DIR}/finder-test.sh" "${ROOTFS}/home/finder-test.sh"

mkdir -p "${ROOTFS}/home/conf"
cp "${FINDER_APP_DIR}/../conf/username.txt" "${ROOTFS}/home/conf/username.txt"
cp "${FINDER_APP_DIR}/../conf/assignment.txt" "${ROOTFS}/home/conf/assignment.txt"

# on the target rootfs
# Copy autorun-qemu.sh if it exists
if [ -f "${FINDER_APP_DIR}/autorun-qemu.sh" ]; then
    cp "${FINDER_APP_DIR}/autorun-qemu.sh" "${ROOTFS}/home/autorun-qemu.sh"
    chmod +x "${ROOTFS}/home/autorun-qemu.sh"
fi

# TODO: Chown the root directory
chmod +x "${ROOTFS}/home/finder.sh"
chmod +x "${ROOTFS}/home/finder-test.sh"
chmod +x "${ROOTFS}/home/writer"

# TODO: Create initramfs.cpio.gz
cd "${ROOTFS}"
find . | cpio -H newc -ov --owner root:root >  gzip -f > "${OUTDIR}/initramfs.cpio.gz"
