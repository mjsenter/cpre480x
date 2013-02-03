CFLAGS+=-Wall -fPIC -shared -g

all: makedirectories libGL.so.1 libGL.so.1.32

libGL.so.1: libGL.so
	ln -sf $< ../../lib64/$@

libGL.so.1.32: libGL.so.32
	ln -sf libGL.so ../../lib/libGL.so.1


build/%.o : %.c ../../libSGPUtils.a 
	cc $(CFLAGS) $(INCLUDE_PATH) -I../../include -o $@ -c $<

build/%.o.32 : %.c
	cc $(CFLAGS) -m32 $(INCLUDE_PATH) -I../../include -o $@ -c $<

libGL.so: build/gltrace.o build/glwrapper.o build/font.o build/input.o build/log.o build/dll.o build/simple2D.o
	ld -shared -soname libGL.so.1 -o ../../lib64/$@ $^ -L../../lib64 -ldl -lSGPUtils
	cp simple2D.h ../../include/simple2D.h

libGL.so.32: build/gltrace.o.32 build/glwrapper.o.32 build/font.o.32 build/input.o.32 build/log.o.32 build/dll.o.32 build/simple2D.o.32
	ld -m elf_i386 -shared -soname libGL.so.1 -o ../../lib/libGL.so $^ -L../../lib -ldl -lSGPUtils

../../libSGPUtils.a:
	make -C ../sgpDriverUtils/ all

makedirectories:
	mkdir -p build

clean:
	rm -f *~ *.o *.so
	rm -f ../../lib64/libGL*
	rm -f ../../lib/libGL*
	rm -f ../../include/simple2D.h
	rm -rf build
