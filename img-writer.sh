#!/bin/bash

TMP_DIR="/tmp/img-writer"
FULL_PATH=""
BLOCK_DEVICE=()
TARGET=""
TARGET_SIZE=""

decompress()
{
   echo "----------------------------------------"
   echo "         Decompressing Image"
   echo "----------------------------------------"
   
   local file=$(ls $TMP_DIR *.img.gz)
   concatenate_paths $TMP_DIR $file
   
   if [[ -f $FULL_PATH ]] ; then 
      echo "Checking file integrity....."
      gunzip -qt $FULL_PATH
      if [ "$?" == 0  ] ; then
         echo "Integrity check complete...."
         echo "Decompressing image...."
         gunzip $FULL_PATH
         echo "Image decompression complete...."
      else
         echo "Integrity check failed...."
         echo "Please check the file and try again...."
         clean_up
         exit 1
      fi
   else
      echo "Error: No image file or file not found"
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

   local image_file=$(ls $TMP_DIR *.img)
   concatenate_paths $TMP_DIR $image_file
   
   local image_size=$(du -kh $FULL_PATH | cut -f1 | grep -o '[0-9]\+\.[0-9]\+')
   local target=$(echo $TARGET_SIZE | grep -o '[0-9]\+\.[0-9]\+')
   local max_resize=$(echo "scale=2;$target-$image_size" | bc)
   
   echo "The maximum resize value for the target disk is: $max_resize GiB"
   printf "Press enter to accept the default or enter a new value: "
   read value
   
   if [ $value ] ; then
      echo "New value will be used"
      #qemu-img resize $FULL_PATH +$value
   else
      echo "Default value will be used"
      #qemu-img resize $FULL_PATH +$max_resize
   fi
}

write()
{
   echo "----------------------------------------"
   echo "         Copying Image to Drive"
   echo "----------------------------------------"
   
   echo ""
   printf "WARNING: All data on $TARGET will be destroyed. Are you sure (Yes/No) "
   read answer
   
   if [ "$answer" == "Yes" ] ; then
      dd status='progress' if=$1 of=$2 bs=1M
   else
      echo "Aborting..."
   fi
}

setup_temp_dir()
{
   echo "Setting up temp working directory...."
   mkdir -p /tmp/img-writer/
   
   if [ -f "$2" ] ; then
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
      resize_image
      #write
      clean_up
   fi
}

main $@
