all :
	if [ ! -d "./build" ]; then mkdir -vp ./build; fi
	if [ ! -e "./build/xenial-server-cloudimg-amd64.ova" ]; then wget -nv -nc -P build/ https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64.ova; fi
	$(MAKE) -C iso
	$(MAKE) -C scripts
	cd build && tar -cvf ../kubecon_usb.tar . && cd ..

clean :
	rm -rf kubecon_usb.tar build/
	cd iso; make clean; cd ..
