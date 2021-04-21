#!/bin/bash

set -eao pipefail

if [ ! -f 512-byte-vm.raw ]; then
  echo -e  "\033[0;31mPlease run build.sh first.\033[0m" >&2
  exit 1
fi

if [ "$(which gocr | wc -l)" -ne 1 ]; then
  echo -e  "\033[0;31mPlease install gocr to run this test.\033[0m" >&2
  exit 1
fi

if [ "$(which qemu-system-x86_64 | wc -l)" -ne 1 ]; then
  echo -e "\033[0;31mPlease install qemu to run this test.\033[0m" >&2
  exit 1
fi

if [ "$(which nc | wc -l)" -ne 1 ]; then
  echo -e "\033[0;31mPlease install netcat to run this test.\033[0m" >&2
  exit 1
fi

echo "Starting VM..."
(
  qemu-system-x86_64 \
    -nographic \
    -serial mon:stdio \
    -drive file=512-byte-vm.raw,format=raw \
    -monitor telnet::2000,server,nowait >/tmp/qemu.log
) &

sleep 2
echo "Performing screen dump and shutting down VM..."
echo 'screendump /tmp/screendump
quit' | nc localhost 2000 >/dev/null
sleep 1
echo "Performing OCR and evaluating results..."
# We skip the H here because the OCR might interpret the blinking cursor as an underscore instead of a H
if [ $(gocr -m 4 /tmp/screendump | grep 'ello World' | wc -l) -eq 1 ]; then
  echo -e "\033[0;32mTest successful\033[0m"
  exit 0
fi

echo "\033[0;31mNo Hello World found in output!\033[0m"
exit 1
