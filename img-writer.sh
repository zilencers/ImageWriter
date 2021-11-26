#!/bin/bash

decompress()
{
   echo "----------------------------------------"
   echo "         Decompressing Image"
   echo "----------------------------------------"

   if [[ "$1" == "-f" && $(wc -l $2 > 0) ]] ; then
      tar -xf $2
   else
      echo "Error: No image file or file not found"
      exit 1
   fi
}

get_storage_devices()
{
   local devices=( $(fdisk -l | grep -o "\(/dev/sd\)\(a\|b\|c\|\):\s[0-9]*.[0-9]*\sGiB") )
   BLOCK_DEVICE=()

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
   echo ""
}

copy_image()
{
   echo ""
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
      decompress $@
   fi
}

main $@
