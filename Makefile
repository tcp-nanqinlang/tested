obj-m := tcp_nanqinlang-super-powered-testing.o

all:
	make -C /lib/modules/`uname -r`/build M=`pwd` modules CC=/usr/bin/gcc-6

clean:
	make -C /lib/modules/`uname -r`/build M=`pwd` clean

install:
	install tcp_nanqinlang-super-powered-testing.ko /lib/modules/`uname -r`/kernel/net/ipv4
	insmod /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang-super-powered-testing.ko
	depmod -a

uninstall:
	rm /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang-super-powered-testing.ko