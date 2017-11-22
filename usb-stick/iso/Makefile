all :
	if [ ! -d "image/packages" ]; then mkdir -vp image/packages; fi
	wget -nc -nv -P image/packages -i packages.list
	cp install.sh image/packages/
	./build.sh intel-kubecon.iso
	if [ ! -d "../build" ]; then mkdir -vp ../build; fi
	cp intel-kubecon.iso ../build/

clean :
	rm -rf image/packages