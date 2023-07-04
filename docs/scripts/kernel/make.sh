INITRD=$1
OUT=$2

cd $INITRD

# Add the first microcode firmware
# --------------------------------

cd early
find . -print0 | cpio --null --create --format=newc > $OUT

# Add the second microcode firmware
# ---------------------------------

cd ../early2
find . -print0 | cpio --null --create --format=newc >> $OUT

# Add the ram fs file system
# --------------------------

cd ../main
find . | cpio --create --format=newc >> $OUT