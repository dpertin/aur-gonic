# Maintainer: Dimitri Pertin <pertin (dot) dimitri (at) protonmail (dot) com>
pkgname=gonic
pkgver=0.9.0
pkgrel=1
pkgdesc='A lightweight music streaming server which implements the Subsonic API'
arch=('x86_64')
depends=('alsa-lib' 'gcc-libs' 'sqlite' 'taglib')
makedepends=('go')
optdepends=('ffmpeg: on-the-fly audio transcoding and caching')
url='https://github.com/sentriz/gonic'
license=('GPL3')
backup=("usr/lib/systemd/system/$pkgname.service")
install="$pkgname.install"
source=("$pkgname-$pkgver.tar.gz::https://github.com/sentriz/gonic/archive/v$pkgver.tar.gz"
        "$pkgname.install"
        "$pkgname.service"
        "$pkgname.sysusers"
        "$pkgname.tmpfiles")
md5sums=('60485d7d2bf3756a990489c1d88ac4ec'
         '1b70d272745c2c4cf5ea3be9445f508d'
         '42cafc55316a6fa709eb873afe037a6d'
         '6ca6715be2cdd424846f7b37b98905f6'
         '487fe9a172e33d86514cf3dbb3b629b8')


build() {
        export CGO_LDFLAGS="${LDFLAGS}"
        export GOFLAGS="-trimpath"
	cd "$srcdir/$pkgname-$pkgver"
	./_do_build_server
}

package() {
	install -Dm644 "$pkgname.service" "$pkgdir/usr/lib/systemd/system/$pkgname.service"
	install -Dm644 "$pkgname.sysusers" "$pkgdir/usr/lib/sysusers.d/$pkgname.conf"
	install -Dm644 "$pkgname.tmpfiles" "$pkgdir/usr/lib/tmpfiles.d/$pkgname.conf"

	cd "$srcdir/$pkgname-$pkgver"
	install -Dm755 ${pkgname} "$pkgdir/usr/bin/${pkgname}"
}

