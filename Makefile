gomobile:
	gomobile bind -target=ios -o txqr.framework github.com/divan/txqr/mobile

aar:
	mkdir -p flutter_app/android/app/libs
	gomobile bind -target=android -o flutter_app/android/app/libs/txqr.aar github.com/divan/txqr/mobile