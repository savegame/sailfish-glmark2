Name:       harbour-glmark2
Summary:    GLMark 2 
Release:    1
Version:    1.0.1
Group:      Amusements/Games
License:    GPLv3
BuildArch:  %{_arch}
URL:        https://github.com/savegame/sailfish-glmark2
Source0:    %{name}.tar.gz

BuildRequires: wayland-devel
BuildRequires: wayland-egl-devel
BuildRequires: wayland-protocols-devel
BuildRequires: systemd-devel
BuildRequires: libGLESv2-devel
BuildRequires: rsync

%global build_folder %{_topdir}/BUILD/build

%description
glmark2 is developed by Alexandros Frantzis and Jesse Barker based on the
original glmark benchmark by Ben Smith.
SailfishOS port made by sashikknox <sashikknox@gmail.com>

%prep
echo "Unpack sources"
# rm -fr %{_topdir}/BUILD
# mkdir -p %{_topdir}/BUILD
cd %{_topdir}/BUILD
tar -xzf %{_topdir}/SOURCES/%{name}.tar.gz
# build libjpeg
cd sailfish/libjpeg-turbo-2.1.3
cmake -Bbuild -DENABLE_STATIC=TRUE -DENABLE_SHARED=FALSE -DWITH_TURBOJPEG=FALSE -DWITH_SIMD=FALSE .

%build
cd %{_topdir}/BUILD/sailfish/libjpeg-turbo-2.1.3/build
make -j12
cd %{_topdir}/BUILD/
./waf configure \
    --with-flavors=wayland-glesv2 \
    --data-path=%{_datadir}/%{name}/data \
    --prefix=/usr \
    --no-debug

./waf build -j`nproc`
# strip build/src/glmark2-es2-wayland


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/{bin,share/%{name}/data,share/applications}
mkdir -p %{buildroot}/usr/share/icons/hicolor/{86x86,108x108,128x128,172x172}/apps/
rsync -avP %{build_folder}/src/glmark2-es2-wayland %{buildroot}%{_bindir}/%{name}
rsync -avP %{_topdir}/BUILD/android/assets/{models,textures,shaders} %{buildroot}%{_datadir}/%{name}/data/
rsync -avP %{_topdir}/BUILD/sailfish/harbour-glmark2.desktop %{buildroot}%{_datadir}/applications/%{name}.desktop
rsync -avP %{_topdir}/BUILD/sailfish/icon_86.png %{buildroot}/usr/share/icons/hicolor/86x86/apps/%{name}.png
rsync -avP %{_topdir}/BUILD/sailfish/icon_108.png %{buildroot}/usr/share/icons/hicolor/108x108/apps/%{name}.png
rsync -avP %{_topdir}/BUILD/sailfish/icon_128.png %{buildroot}/usr/share/icons/hicolor/128x128/apps/%{name}.png
rsync -avP %{_topdir}/BUILD/sailfish/icon_172.png %{buildroot}/usr/share/icons/hicolor/172x172/apps/%{name}.png

%files
%defattr(-,root,root,-)
%attr(755,root,root) %{_bindir}/%{name}
%{_datadir}/icons/hicolor/*
%dir %{_datadir}/%{name}/data
%{_datadir}/%{name}/data/*
%{_datadir}/applications/%{name}.desktop

%changelog 
* Sat Apr 30 2022 sashikknox <sashikknox@gmail.com>
- default launcher run fullscreen render resolution
- default resolution is 800x600
* Fri Apr 29 2022 sashikknox <sashikknox@gmail.com>
- fixes for SailfishOS wayland
