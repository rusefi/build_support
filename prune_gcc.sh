#!/usr/bin/env bash

# Prune unused architectures from ARM GCC toolchain releases

set -e

# regex of architectures to retain
ARCH_REGEX="nofp|v6-m|v7e-m(\+[df]p)?"
# pruned archive prefix
RUSEFI_PREFIX="rusefi-"
# tar compression program
COMPRESSION_PROGRAM="xz -T0 -9e"
# compressed tarball suffix, needs to match $COMPRESSION_PROGRAM
COMPRESSION_SUFFIX=".xz"
# temporary working directory
TMP_DIR="/tmp/rusefi-process_gcc"

ARCHIVE="${1}"
if [ -z "${1}" ]; then
	echo "usage: ${0} ARCHIVE"
	exit
fi

archive_tar="${ARCHIVE%.*}"
rusefi_archive="${RUSEFI_PREFIX}${archive_tar}${COMPRESSION_SUFFIX}"

# Cleanup prior [failed] runs
rm -rf "${TMP_DIR}"

# Extract original archive
echo Extracting ${ARCHIVE}
dir="$(pwd)"
mkdir -p "${TMP_DIR}"
tar -C "${TMP_DIR}" -xaf "${ARCHIVE}"
pushd "${TMP_DIR}" >/dev/null
archive_dir="$(echo *)"

# Prune unused architecture objects
pushd ${archive_dir} >/dev/null
for path in arm-none-eabi/lib/thumb/*; do
	arch="${path##*/}"
	echo ${arch} | grep -Eq ${ARCH_REGEX} \
		&& continue

	echo Pruning architecture ${arch}

	rm -rf arm-none-eabi/include/c++/*/arm-none-eabi/thumb/${arch}
	rm -rf arm-none-eabi/lib/thumb/${arch}
	rm -rf lib/gcc/arm-none-eabi/*/thumb/${arch}
done
popd >/dev/null

# Create rusEFI archive
echo Creating ${rusefi_archive}
tar -I "${COMPRESSION_PROGRAM}" -cf "${dir}/${rusefi_archive}" "${archive_dir}"
popd >/dev/null

# Cleanup
rm -rf "${TMP_DIR}"
