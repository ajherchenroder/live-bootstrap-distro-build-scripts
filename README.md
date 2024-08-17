# live-bootstrap-distro-build-scripts
This is my repository for storing distro build scripts to be built in the live bootstrap environment. They are intended to be built under the environment built from the following repository:

https://github.com/ajherchenroder/live-bootstrap-with-lfs

The intent of these scripts is to build install media for the distro in question in a live-bootstrap environment built from source. Then the distro can be installed as normal using their internal tool set.   

Builds work in progress:
Gentoo Prefix

working:
Netbsd

To Do:
Debian
Trunas Scale
Proxmox

On Hold:
Freebsd
Gentoo

Netbsd notes:
You will need a fourth partition in order to use this script. You will also need an additional USB stick or cd/dvd burner to install the final media to. I have used a 128GB USB stick to perform the build on and an additional 64 GB stick for the final Netbsd install media.

Netbsd Directions.
1) Clone and build the https://github.com/ajherchenroder/live-bootstrap-with-lfs per it's instructions.
2) In the final LFS environment root directory run the lfstarget.sh script.
3) cd into the target directory.
4) Make the netbsdmk.sh executable if it isn't already by entering chmod +x /target/netbsdmk.sh
5) Run the netbsdmk.sh script and follow the directions. The final media will be in the /mnt/netbsd/media folder.
6) copy it onto the install stick by running DD if=/mnt/netbsd/media/NetBSD(version number)-amd64-install.img of=(location of the build stick).
7) Run the Netbsd install as normal and update it to the latest version.
