#!/bin/sh -x

case `uname -m` in
armv*)
  ARCH_CFLAGS="-DTARGET_arm"
 ;;
*)
  ARCH_CFLAGS="-DTARGET_amd64 -D__x86_64__ -m64 -mno-red-zone -momit-leaf-frame-pointer -mfancy-math-387"
  ;;
esac

PKG_CONFIG_DEPS="openlibm libminios-xen >= 0.5"
pkg-config --print-errors --exists ${PKG_CONFIG_DEPS} || exit 1

# This extra flag only needed for gcc 4.8+
GCC_MVER2=`gcc -dumpversion | cut -f2 -d.`
if [ $GCC_MVER2 -ge 8 ]; then
  EXTRA_CFLAGS=-fno-tree-loop-distribute-patterns
fi

case "$1" in
xen)
  CC=${CC:-cc}
  PWD=`pwd`
  GCC_INCLUDE=`env LANG=C ${CC} -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p'`
  CFLAGS="$EXTRA_CFLAGS -O3 -U __linux__ -U __FreeBSD__ -U __sun__ \
    -D__XEN_INTERFACE_VERSION__=0x00030205 -D__INSIDE_MINIOS__ -nostdinc -std=gnu99 \
    -fno-stack-protector -fno-reorder-blocks -fstrict-aliasing \
    -I${GCC_INCLUDE}/include \
    -I ${PWD}/runtime/include/ \
    -DCAML_NAME_SPACE \
    -DSYS_xen -I${PWD}/runtime/ocaml $(pkg-config --cflags $PKG_CONFIG_DEPS) \
    -Wextra -Wchar-subscripts -Wno-switch \
    -Wno-unused -Wredundant-decls \
    -fno-builtin \
    -DNATIVE_CODE ${ARCH_CFLAGS}"
  ;;
*)
  CC="${CC:-cc}"
  CFLAGS="-Wall -O3"
  ;;
esac
