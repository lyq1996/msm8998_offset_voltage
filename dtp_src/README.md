emmm, dynamic cross compile is still broken, seem that arm-linux-gnueabi-gcc dymatic linker doesn't work on android.

```
make CC=arm-linux-gnueabi-gcc -static
```