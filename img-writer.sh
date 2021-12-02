#!/bin/bash

TMP_DIR="/tmp/img-writer"
IMAGE_NAME=""
FULL_PATH=""
BLOCK_DEVICE=()
TARGET=""
TARGET_SIZE=""

decompress()
{
   echo "----------------------------------------"
   echo "         Decompressing Image"
   echo "----------------------------------------"
   
   concatenate_paths $TMP_DIR $IMAGE_NAME
   local file_type=$(file $FULL_PATH | grep -o "\(Zip\|7-zip\|rar\|gzip\)")
   
   if [ ! $file_type ] ; then
      echo "Image file is not compressed.....skipping"
   else
      check_integrity $file_type
      echo "Decompressing image...."
      
      case $file_type in
        'gzip')
           gunzip $FULL_PATH
           ;;
        'Zip')
           unzip $FULL_PATH
           ;;
        '7-zip')
           7z e $FULL_PATH $TMP_DIR
           ;;
        'rar')
           unrar $FULL_PATH
           ;;
      esac
      echo "Image decompression complete...."
   fi
}

check_integrity()
{
   echo "Checking file integrity..."
   
   case $1 in
       'gzip')
          gunzip -qt $FULL_PATH
          ;;
       'Zip')
          zip -qT $FULL_PATH
          ;;
       '7-zip')
          7z t -so $FULL_PATH
          ;;
       'rar')
           unrar t $FULL_PATH
          ;;
   esac

   if [ "$?" == 0  ] ; then
      echo "Integrity check complete...."
   else
      echo "Integrity check failed...."
      echo "Please check the file and try again...."
      clean_up
      exit 1   
   fi
}

concatenate_paths() 
{
   local base_path=${1}
   local sub_path=${2}
   local full_path="${base_path:+$base_path/}$sub_path"
   FULL_PATH=$(realpath ${full_path})
}

get_storage_devices()
{
   local devices=( $(fdisk -l | grep -o "\(/dev/sd\)\(a\|b\|c\|\):\s[0-9]*.[0-9]*\sGiB") )
   
   for ((i=0 ; i < "${#devices[@]}"; i++)); 
   do
      BLOCK_DEVICE+=("${devices[$i]} ${devices[i+=1]} ${devices[i+=1]}")
   done
}

get_target()
{
   echo ""
   echo "Please choose target block device: "
   
   for ((i=0 ; i < "${#BLOCK_DEVICE[@]}"; i++)); 
   do
      echo "$i) ${BLOCK_DEVICE[$i]}"
   done
   
   read choice
   TARGET=${BLOCK_DEVICE[$choice]}
}

get_target_size()
{
  TARGET_SIZE=$(echo $TARGET | grep -o "[0-9]*\.[0-9]*\sGiB")
}

convert_image()
{
   echo "----------------------------------------"
   echo "         Converting Image"
   echo "----------------------------------------"
   
   # qcow2, vdi, vmdk, vhd

}

resize_image()
{
   echo "----------------------------------------"
   echo "         Resizing Image"
   echo "----------------------------------------"

   if [ ! $(which qemu-img) ] ; then
      echo "Error: qemu-img not found"
      echo "Install with apt install qemu-utils"
      exit 1
   fi

   IMAGE_NAME=$(ls $TMP_DIR)
   concatenate_paths $TMP_DIR $IMAGE_NAME
   
   local image_size=$(du -kh $FULL_PATH | cut -f1 | grep -o '[0-9]\+\.[0-9]\+')
   local target=$(echo $TARGET_SIZE | grep -o '[0-9]\+\.[0-9]\+')
   local max_resize=$(echo "scale=2;$target-$image_size" | bc)
   
#   echo "The maximum resize value for the target disk is: $max_resize GiB"
#   printf "Press enter to accept the default or enter a new value: "
#   read value
   
#   if [ $value ] ; then
#      qemu-img resize -f raw $FULL_PATH +$value'G'
#   else
#      qemu-img resize -f raw $FULL_PATH +$max_resize'G'
#   fi
}

remove_partitions()
{
   echo "target: $1"
   echo "partitions: $2"

   for element in $2
   do
      umount "/dev/$element"
      echo "Unmounted /dev/$element"
      read test
      
      fdisk "/dev/$1" << EOF
      d
      
      w
EOF

   done
}

write_to_disk()
{
   echo "----------------------------------------"
   echo "         Copying Image to Drive"
   echo "----------------------------------------"
   
   echo ""
   printf "WARNING: All data on $TARGET will be destroyed. Are you sure (Yes/No) "
   read answer
   
   if [ "$answer" == "Yes" ] ; then
      local target=$(echo $TARGET | grep -o "sd\(a\|b\|c\|d\|e\|f\|g\)")
      local partitions=( $(cat /proc/partitions | grep -o "$target\(1\|2\|3\|4\|5\|6\|7\|8\|9\)") )

      remove_partitions $target $partitions
      #dd status=progress if=$FULL_PATH of=$target bs=1M
   else
      echo "Aborting..."
   fi
}

setup_temp_dir()
{
   echo "Setting up temp working directory...."
   mkdir -p /tmp/img-writer/
   
   if [ -f "$2" ] ; then
      IMAGE_NAME=$(basename $2)
      cp $2 $TMP_DIR/
   fi
}

clean_up()
{
   echo "Cleaning up..."
   echo "Removing temporary directory..."
   rm -r $TMP_DIR
   echo "Clean up complete..."
}

title()
{
   echo "----------------------------------------"
   echo "              Img Writer"
   echo "                 v0.1"
   echo "----------------------------------------"
}

help()
{
   echo "Usage: img-writer [option]"
   echo "Short Options:"
   echo "	-h	Print help menu"
   echo "	-f	Image filename"
   echo ""
}

main()
{
   if [ "$1" == "-h" ] ; then
      help
   else
      title
      get_storage_devices
      get_target
      get_target_size
      setup_temp_dir $@
      decompress
      #convert_image
      #resize_image
      #write_to_disk
      #clean_up
   fi
}

main $@
