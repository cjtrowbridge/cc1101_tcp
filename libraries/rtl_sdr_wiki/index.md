-   **Table of contents**
-   [rtl-sdr](https://osmocom.org/projects/rtl-sdr/wiki#rtl-sdr)
    -   [Specifications](https://osmocom.org/projects/rtl-sdr/wiki#Specifications)
    -   [Supported Hardware](https://osmocom.org/projects/rtl-sdr/wiki#Supported-Hardware)
    -   [Software](https://osmocom.org/projects/rtl-sdr/wiki#Software)
        -   [Binary Builds](https://osmocom.org/projects/rtl-sdr/wiki#Binary-Builds)
            -   [Windows](https://osmocom.org/projects/rtl-sdr/wiki#Windows)
        -   [Source Code](https://osmocom.org/projects/rtl-sdr/wiki#Source-Code)
            -   [Source code releases](https://osmocom.org/projects/rtl-sdr/wiki#Source-code-releases)
        -   [Building the software](https://osmocom.org/projects/rtl-sdr/wiki#Building-the-software)
            -   [rtlsdr library & capture tool](https://osmocom.org/projects/rtl-sdr/wiki#rtlsdr-library-amp-capture-tool)
            -   [Gnuradio Source](https://osmocom.org/projects/rtl-sdr/wiki#Gnuradio-Source)
            -   [Automated installation](https://osmocom.org/projects/rtl-sdr/wiki#Automated-installation)
    -   [Mailing List](https://osmocom.org/projects/rtl-sdr/wiki#Mailing-List)
        -   [Usage](https://osmocom.org/projects/rtl-sdr/wiki#Usage)
            -   [rtl-sdr](https://osmocom.org/projects/rtl-sdr/wiki#rtl-sdr-2)
            -   [rtl\_tcp](https://osmocom.org/projects/rtl-sdr/wiki#rtl_tcp)
            -   [rtl\_test](https://osmocom.org/projects/rtl-sdr/wiki#rtl_test)
    -   [Using the data](https://osmocom.org/projects/rtl-sdr/wiki#Using-the-data)
    -   [Known Apps](https://osmocom.org/projects/rtl-sdr/wiki#Known-Apps)
    -   [Credits](https://osmocom.org/projects/rtl-sdr/wiki#Credits)

DVB-T dongles based on the Realtek RTL2832U can be used as a cheap SDR, since the chip allows transferring the raw I/Q samples to the host, which is officially used for DAB/DAB+/FM demodulation. The possibility of this has been discovered by Eric Fry ([History and Discovery of RTLSDR](http://rtlsdr.org/#history_and_discovery_of_rtlsdr)). Antti Palosaari has not been involved in development of rtl-sdr.

## Specifications[¶](https://osmocom.org/projects/rtl-sdr/wiki#Specifications)

The RTL2832U outputs 8-bit I/Q-samples, and the highest theoretically possible sample-rate is 3.2 MS/s, however, the highest sample-rate without lost samples that has been tested wit regular USB controllers so far is 2.4 MS/s. A stable sample-rate of 3.2 MS/s without lost samples is only possible with the Etron EJ168/EJ188/EJ198 series of host controllers due to their [specific maximum latency](https://osmocom.org/attachments/3979/Histo_DATA_Packets.png). The frequency range is highly dependent of the used tuner, **dongles that use the Elonics E4000 offer the widest possible range (see table below)**.

<table><tbody><tr><td><strong>Tuner</strong></td><td><strong>Frequency range</strong></td></tr><tr><td>Elonics E4000</td><td>52 - 2200 MHz with a gap from 1100 MHz to 1250 MHz (varies)</td></tr><tr><td>Rafael Micro R820T</td><td>24 - 1766 MHz</td></tr><tr><td>Rafael Micro R828D</td><td>24 - 1766 MHz</td></tr><tr><td>Fitipower FC0013</td><td>22 - 1100 MHz (FC0013B/C, FC0013G has a separate L-band input, which is unconnected on most sticks)</td></tr><tr><td>Fitipower FC0012</td><td>22 - 948.6 MHz</td></tr><tr><td>FCI FC2580</td><td>146 - 308 MHz and 438 - 924 MHz (gap in between)</td></tr></tbody></table>

## Supported Hardware[¶](https://osmocom.org/projects/rtl-sdr/wiki#Supported-Hardware)

**Note:** Many devices with EEPROM have 0x2838 as PID and RTL2838 as product name, but in fact all of them have an RTL2832U inside.  
Realtek never released a chip marked as RTL2838 so far.  
The following devices are known to work fine with RTLSDR software:

<table><tbody><tr><td><strong>VID</strong></td><td><strong>PID</strong></td><td><strong>tuner</strong></td><td><strong>device name</strong></td></tr><tr><td>0x0bda</td><td>0x2832</td><td>all of them</td><td>Generic RTL2832U (e.g. hama nano)</td></tr><tr><td>0x0bda</td><td>0x2838</td><td>E4000</td><td>ezcap USB 2.0 DVB-T/DAB/FM dongle</td></tr><tr><td>0x0ccd</td><td>0x00a9</td><td>FC0012</td><td>Terratec Cinergy T Stick Black (rev 1)</td></tr><tr><td>0x0ccd</td><td>0x00b3</td><td>FC0013</td><td>Terratec NOXON DAB/DAB+ USB dongle (rev 1)</td></tr><tr><td>0x0ccd</td><td>0x00d3</td><td>E4000</td><td>Terratec Cinergy T Stick RC (Rev.3)</td></tr><tr><td>0x0ccd</td><td>0x00e0</td><td>E4000</td><td>Terratec NOXON DAB/DAB+ USB dongle (rev 2)</td></tr><tr><td>0x185b</td><td>0x0620</td><td>E4000</td><td>Compro Videomate U620F</td></tr><tr><td>0x185b</td><td>0x0650</td><td>E4000</td><td>Compro Videomate U650F</td></tr><tr><td>0x1f4d</td><td>0xb803</td><td>FC0012</td><td>GTek T803</td></tr><tr><td>0x1f4d</td><td>0xc803</td><td>FC0012</td><td>Lifeview LV5TDeluxe</td></tr><tr><td>0x1b80</td><td>0xd3a4</td><td>FC0013</td><td>Twintech UT-40</td></tr><tr><td>0x1d19</td><td>0x1101</td><td>FC2580</td><td>Dexatek DK DVB-T Dongle (Logilink VG0002A)</td></tr><tr><td>0x1d19</td><td>0x1102</td><td>?</td><td>Dexatek DK DVB-T Dongle (MSI <a href="https://osmocom.org/projects/rtl-sdr/wiki/DigiVox?parent=Rtl-sdr">DigiVox</a> mini II V3.0)</td></tr><tr><td>0x1d19</td><td>0x1103</td><td>FC2580</td><td>Dexatek Technology Ltd. DK 5217 DVB-T Dongle</td></tr><tr><td>0x0458</td><td>0x707f</td><td>?</td><td>Genius TVGo DVB-T03 USB dongle (Ver. B)</td></tr><tr><td>0x1b80</td><td>0xd393</td><td>FC0012</td><td>GIGABYTE GT-U7300</td></tr><tr><td>0x1b80</td><td>0xd394</td><td>?</td><td>DIKOM USB-DVBT HD</td></tr><tr><td>0x1b80</td><td>0xd395</td><td>FC0012</td><td>Peak 102569AGPK</td></tr><tr><td>0x1b80</td><td>0xd39d</td><td>FC0012</td><td>SVEON STV20 DVB-T USB &amp; FM</td></tr></tbody></table>

People over at reddit [are collecting a list](http://www.reddit.com/r/RTLSDR/comments/s6ddo/rtlsdr_compatibility_list_v2_work_in_progress/ "v2") of other devices that are compatible.

If you find a device that is not yet in the device list but should be supported, please send the VID/PID and additional info (used tuner, device name) to our mailing list.

This is the PCB of the ezcap-stick:  
![top view of the ezcap PCB](https://osmocom.org/attachments/download/2243/ezcap_top.jpg "top view of the ezcap PCB")  
More pictures can be found [here](http://www.steve-m.de/pictures/rtl-sdr/).

## Software[¶](https://osmocom.org/projects/rtl-sdr/wiki#Software)

Much software is available for the RTL2832. Most of the user-level packages rely on the librtlsdr library which comes as part of the rtl-sdr codebase. This codebase contains both the library itself and also a number of command line tools such as rtl\_test, rtl\_sdr, rtl\_tcp, and rtl\_fm. These command line tools use the library to test for the existence of RTL2832 devices and to perform basic data transfer functions to and from the device.

Because most of the RTL2832 devices are connected using USB, the librtlsdr library depends on the libusb library to communicate with the device.

At the user level, there are several options for interacting with the hardware. The rtl-sdr codebase contains a basic FM receiver program that operates from the command line. The rtl\_fm program is a command line tool that can initialize the RTL2832, tune to a given frequency, and output the received audio to a file or pipe the output to command line audio players such as the alsa aplay or the sox play commands. There is also the rtl\_sdr program that will output the raw I-Q data to a file for more basic analysis.

For example, the following command will do reception of commercial wide-band FM signals:

```
rtl_fm -f 96.3e6 -M wbfm -s 200000 -r 48000 - | aplay -r 48k -f S16_LE

```

On a Mac, a similar command that works is as follows. This assumes that the sox package is installed, 'port install sox':

```
rtl_fm -f 90100000 -M wbfm -s 200000 -r 48000 - | play -r 48000 -t s16 -L -c 1  -

```

If you want to do more advanced experiments, the GNU Radio collection of tools can be used to build custom radio devices. GNU Radio can be used both from a GUI perspective in which you can drag-and-drop radio components to build a radio and also programmatically where software programs written in C or Python are created that directly reference the internal GNU Radio functions.

The use of GNU Radio is attractive because of the large number of pre-built functions that can easily be connected together. However, be aware that this is a large body of software with dependencies on many libraries. Thankfully there is a simple script that will perform the installation but still, the time required can be on the order of hours. When starting out, it might be good to try the command line programs that come with the rtl-sdr package first and then install the GNU Radio system later.

### Binary Builds[¶](https://osmocom.org/projects/rtl-sdr/wiki#Binary-Builds)

#### Windows[¶](https://osmocom.org/projects/rtl-sdr/wiki#Windows)

While Osmocom in general is a very much Linux-centric development community, we are now finally publishing automatic weekly Windows binary builds for the most widely used Osmocom SDR related projects: [rtl-sdr](https://osmocom.org/projects/rtl-sdr/wiki) and [osmo-fl2k](https://osmocom.org/projects/osmo-fl2k/wiki).

You can find the binaries at

-   [https://ftp.osmocom.org/binaries/windows/osmo-fl2k/](https://ftp.osmocom.org/binaries/windows/osmo-fl2k/)
-   [https://ftp.osmocom.org/binaries/windows/rtl-sdr/](https://ftp.osmocom.org/binaries/windows/rtl-sdr/)

The actual builds are done by [@roox](https://osmocom.org/users/27043) who is building them using MinGW on OBS, see

-   [https://build.opensuse.org/project/show/network:osmocom:mingw:mingw32](https://build.opensuse.org/project/show/network:osmocom:mingw:mingw32) and
-   [https://build.opensuse.org/project/show/network:osmocom:mingw:mingw64](https://build.opensuse.org/project/show/network:osmocom:mingw:mingw64)

The status of the osmocom binary publish job, executed once per week from now on, can be found at [https://jenkins.osmocom.org/jenkins/view/All%20no%20Gerrit/job/Osmocom-OBS\_MinGW\_weekly\_publish/](https://jenkins.osmocom.org/jenkins/view/All%20no%20Gerrit/job/Osmocom-OBS_MinGW_weekly_publish/)

### Source Code[¶](https://osmocom.org/projects/rtl-sdr/wiki#Source-Code)

The rtl-sdr code can be checked out with:  

```
git clone https://gitea.osmocom.org/sdr/rtl-sdr.git

```

It can also be browsed via [gitea](https://gitea.osmocom.org/sdr/rtl-sdr/), and there's an official [mirror on github](https://github.com/osmocom/rtl-sdr) that also provides [tagged releases](https://github.com/osmocom/rtl-sdr/tags).

If you are going to "fork it on github" and enhance it, please contribute back and submit your patches to: osmocom-sdr at lists.osmocom.org

A [gr-osmosdr](https://osmocom.org/projects/gr-osmosdr/wiki) GNU Radio source block for [OsmoSDR](https://osmocom.org/projects/osmosdr/wiki) **and rtl-sdr** is available. **Please install a recent gnuradio (>= v3.6.4) in order to be able to use it.**

#### Source code releases[¶](https://osmocom.org/projects/rtl-sdr/wiki#Source-code-releases)

Source code release tarballs are available at [https://downloads.osmocom.org/releases/rtl-sdr/](https://downloads.osmocom.org/releases/rtl-sdr/)

### Building the software[¶](https://osmocom.org/projects/rtl-sdr/wiki#Building-the-software)

#### rtlsdr library & capture tool[¶](https://osmocom.org/projects/rtl-sdr/wiki#rtlsdr-library-amp-capture-tool)

**You have to install development packages for libusb1.0** and can either use cmake or autotools to build the software.

Please note: prior pulling a new version from git and compiling it, please do a "make uninstall" first to properly remove the previous version.

Building with cmake:  

```
cd rtl-sdr/
mkdir build
cd build
cmake ../
make
sudo make install
sudo ldconfig

```

In order to be able to use the dongle as a non-root user, you may install the appropriate udev rules file by calling cmake with -DINSTALL\_UDEV\_RULES=ON argument in the above build steps.  

```
cmake ../ -DINSTALL_UDEV_RULES=ON

```

Building with autotools:  

```
cd rtl-sdr/
autoreconf -i
./configure
make
sudo make install
sudo ldconfig

```

The built executables (rtl\_sdr, rtl\_tcp and rtl\_test) can be found in rtl-sdr/src/.

In order to be able to use the dongle as a non-root user, you may install the appropriate udev rules file by calling  

```
sudo make install-udev-rules

```

#### Gnuradio Source[¶](https://osmocom.org/projects/rtl-sdr/wiki#Gnuradio-Source)

**The Gnu Radio source requires a recent gnuradio (>= v3.7 if building master branch or 3.6.5 when building gr3.6 branch) to be installed.**

The source supports direct device operation as well as a tcp client mode when using the rtl\_tcp utility as a spectrum server.

Please note: prior pulling a new version from git and compiling it, please do a "make uninstall" first to properly remove the previous version.

Please note: you always should build & **install the latest version of the dependencies (librtlsdr in this case)** before trying to build the gr source. The build system of gr-osmosdr will recognize them and enable specific source/sink components thereafter.

Building with cmake (as described in the [gr-osmosdr wiki page](https://osmocom.org/projects/rtl-sdr/wiki/GrOsmoSDR?parent=Rtl-sdr)):

```
git clone https://gitea.osmocom.org/sdr/gr-osmosdr
cd gr-osmosdr/

```

If you are building for gnuradio 3.6 series, you have to switch to the gr3.6 branch as follows  

```
git checkout gr3.6

```

then continue with

```
mkdir build
cd build/
cmake ../

```

Now cmake should print out a summary of enabled/disabled components. You may disable certain components by following guidelines shown by cmake. Make sure the device of your interest is listed here. Check your dependencies and retry otherwise.  

```
-- ######################################################
-- # gr-osmosdr enabled components                         
-- ######################################################
--   * Python support
--   * Osmocom IQ Imbalance Correction
--   * sysmocom [[OsmoSDR]]
--   * [[FunCube]] Dongle
--   * IQ File Source
--   * Osmocom RTLSDR
--   * RTLSDR TCP Client
--   * Ettus USRP Devices
--   * Osmocom [[MiriSDR]]
--   * [[HackRF]] Jawbreaker
-- 
-- ######################################################
-- # gr-osmosdr disabled components                        
-- ######################################################
-- 
-- Building for version: 4c101ea4 / 0.0.1git
-- Using install prefix: /usr/local

```

Now build & install  

```
make
sudo make install
sudo ldconfig

```

NOTE: The osmocom source block (osmocom/RTL-SDR Source) will appear under 'Sources' category in GRC menu.

For initial tests we recommend the multimode receiver gnuradio companion flowgraph (see "Known Apps" table below).

You may find more detailed installation instructions in this recent [tutorial](http://blog.opensecurityresearch.com/2012/06/getting-started-with-gnu-radio-and-rtl.html).

#### Automated installation[¶](https://osmocom.org/projects/rtl-sdr/wiki#Automated-installation)

Marcus D. Leech has kindly integrated the forementioned build steps into his gnuradio installation script at "This is the most user-friendly option so far.

## Mailing List[¶](https://osmocom.org/projects/rtl-sdr/wiki#Mailing-List)

We discuss both [OsmoSDR](https://osmocom.org/projects/rtl-sdr/wiki/OsmoSDR?parent=Rtl-sdr) as well as rtl-sdr on the following

-   web forum: [https://discourse.osmocom.org/c/sdr](https://discourse.osmocom.org/c/sdr)
-   mailing list: \[mailto:[osmocom-sdr@lists.osmocom.org](mailto:osmocom-sdr@lists.osmocom.org)\].

You can subscribe and/or unsubscribe via the following link: [https://lists.osmocom.org/mailman/listinfo/osmocom-sdr](https://lists.osmocom.org/mailman/listinfo/osmocom-sdr)

Please make sure to read the [MailingListRules](https://osmocom.org/projects/cellular-infrastructure/wiki/MailingListRules) before posting.

### Usage[¶](https://osmocom.org/projects/rtl-sdr/wiki#Usage)

#### rtl-sdr[¶](https://osmocom.org/projects/rtl-sdr/wiki#rtl-sdr-2)

Example: To tune to 392.0 MHz, and set the sample-rate to 1.8 MS/s, use:

```
./rtl_sdr /tmp/capture.bin -s 1.8e6 -f 392e6

```

to record samples to a file or to forward the data to a fifo.

If the device can't be opened, make sure you have the appropriate rights to access the device (install udev-rules from the repository, or run it as root).

#### rtl\_tcp[¶](https://osmocom.org/projects/rtl-sdr/wiki#rtl_tcp)

Example:

```
rtl_tcp -a 10.0.0.2 [-p listen port (default: 1234)":http://www.sbrac.org/files/build-gnuradio].
Found 1 device(s).
Found Elonics E4000 tuner
Using Generic RTL2832U (e.g. hama nano)
Tuned to 100000000 Hz.
listening...
Use the device argument 'rtl_tcp=10.0.0.2:1234' in [[OsmoSDR]] (gr-osmosdr) source
to receive samples in GRC and control rtl_tcp parameters (frequency, gain, ...).

```

use the rtl\_tcp=... device argument in gr-osmosdr source to receive the samples in GRC and control the rtl settings remotely.

This application has been successfully crosscompiled for ARM and MIPS devices and is providing IQ data in a networked ADS-B setup at a rate of 2.4MSps. The gr-osmosdr source is being used together with an optimized gr-air-modes version (see Known Apps below).  
It is also available as a package in [OpenWRT](https://osmocom.org/projects/rtl-sdr/wiki/OpenWRT?parent=Rtl-sdr).

A use case is described [here](https://sites.google.com/site/embrtlsdr/).

#### rtl\_test[¶](https://osmocom.org/projects/rtl-sdr/wiki#rtl_test)

To check the possible tuning range (may heavily vary by some MHz depending on device and temperature), call  

```
rtl_test -t

```

To check the maximum samplerate possible on your machine, type (change the rate down until no sample loss occurs):  

```
rtl_test -s 3.2e6

```

A samplerate of 2.4e6 is known to work even over tcp connections (see rtl\_tcp above). A sample rate of 2.88e6 may work without lost samples but this may depend on your PC/Laptop's host interface.

## Using the data[¶](https://osmocom.org/projects/rtl-sdr/wiki#Using-the-data)

To convert the data to a standard cfile, following GNU Radio Block can be used:[br](https://osmocom.org/projects/rtl-sdr/wiki/Br?parent=Rtl-sdr)  
![](https://osmocom.org/attachments/download/2248/rtl2832-cfile.png)  
The GNU Radio Companion flowgraph is available as [rtl2832-cfile.grc](https://osmocom.org/attachments/2247). It is based on the FM demodulation flowgraph posted by Alistair Buxton [on this thread](http://thread.gmane.org/gmane.linux.drivers.video-input-infrastructure/44461/focus=44525).

Please note: for realtime operation you may use fifos (mkfifo) to forward the iq data from the capture utility to the GRC flowgraph.

You may use any of the the following gnuradio sources (they are equivalent):

![gr-osmosdr sources](https://osmocom.org/attachments/download/2244/osmosource.png "gr-osmosdr sources")

What has been successfully tested so far is the reception of [Broadcast FM and air traffic AM](https://www.cgran.org/browser/projects/multimode/trunk) radio, [tetra](https://osmocom.org/projects/tetra/wiki), [gmr](https://osmocom.org/projects/gmr/wiki), [GSM](http://svn.berlin.ccc.de/projects/airprobe/), [ADS-B](https://www.cgran.org/wiki/gr-air-modes) and [POCSAG](https://github.com/smunaut/osmo-pocsag).

Tell us your success story with other wireless protocols in ##rtlsdr channel on the [libera](https://libera.chat/) IRC network.

## Known Apps[¶](https://osmocom.org/projects/rtl-sdr/wiki#Known-Apps)

The following 3rd party applications and libraries are successfully using either librtlsdr directly or the corresponding gnuradio source (gr-osmosdr):

<table><tbody><tr><td><strong>Name</strong></td><td><strong>Type</strong></td><td><strong>Author</strong></td><td><strong>URL</strong></td></tr><tr><td>gr-pocsag</td><td>GRC Flowgraph</td><td>Marcus Leech</td><td><a href="https://www.cgran.org/browser/projects/gr-pocsag/trunk" target="_blank" rel="noopener noreferrer">https://www.cgran.org/browser/projects/gr-pocsag/trunk</a></td></tr><tr><td>multimode RX (try first!)</td><td>GRC Flowgraph</td><td>Marcus Leech</td><td><a href="https://www.cgran.org/browser/projects/multimode/trunk" target="_blank" rel="noopener noreferrer">https://www.cgran.org/browser/projects/multimode/trunk</a></td></tr><tr><td>simple_fm_rvc</td><td>GRC Flowgraph</td><td>Marcus Leech</td><td><a href="https://www.cgran.org/browser/projects/simple_fm_rcv/trunk" target="_blank" rel="noopener noreferrer">https://www.cgran.org/browser/projects/simple_fm_rcv/trunk</a></td></tr><tr><td>python-librtlsdr</td><td>Python Wrapper</td><td>David Basden</td><td><a href="https://github.com/dbasden/python-librtlsdr" target="_blank" rel="noopener noreferrer">https://github.com/dbasden/python-librtlsdr</a></td></tr><tr><td>pyrtlsdr</td><td>Python Wrapper</td><td>Roger</td><td><a href="https://github.com/roger-/pyrtlsdr" target="_blank" rel="noopener noreferrer">https://github.com/roger-/pyrtlsdr</a></td></tr><tr><td>rtlsdr-waterfall</td><td>Python FFT GUI</td><td>Kyle Keen</td><td><a href="https://github.com/keenerd/rtlsdr-waterfall" target="_blank" rel="noopener noreferrer">https://github.com/keenerd/rtlsdr-waterfall</a></td></tr><tr><td>Wireless Temp. Sensor RX</td><td>Gnuradio App</td><td>Kevin Mehall</td><td><a href="https://github.com/kevinmehall/rtlsdr-433m-sensor" target="_blank" rel="noopener noreferrer">https://github.com/kevinmehall/rtlsdr-433m-sensor</a></td></tr><tr><td>QtRadio</td><td>SDR GUI</td><td>Andrea Montefusco et al.</td><td><a href="http://napan.ca/ghpsdr3/index.php/RTL-SDR" target="_blank" rel="noopener noreferrer">http://napan.ca/ghpsdr3/index.php/RTL-SDR</a></td></tr><tr><td>gqrx</td><td>SDR GUI</td><td>Alexandru Csete</td><td><a href="https://github.com/csete/gqrx" target="_blank" rel="noopener noreferrer">https://github.com/csete/gqrx</a></td></tr><tr><td>rtl_fm</td><td>SDR CLI</td><td>Kyle Keen</td><td>merged in librtlsdr master</td></tr><tr><td>SDR#</td><td>SDR GUI</td><td>Youssef Touil</td><td><a href="http://sdrsharp.com/" target="_blank" rel="noopener noreferrer">http://sdrsharp.com/</a> and <a href="http://rtlsdr.org/softwarewindows" target="_blank" rel="noopener noreferrer">Windows Guide</a> or <a href="http://rtlsdr.org/softwarelinux" target="_blank" rel="noopener noreferrer">Linux Guide</a></td></tr><tr><td>tetra_demod_fft</td><td>Trunking RX</td><td>osmocom team</td><td><a href="http://cgit.osmocom.org/cgit/osmo-tetra/tree/src/demod/python/osmosdr-tetra_demod_fft.py" target="_blank" rel="noopener noreferrer">osmosdr-tetra_demod_fft.py</a> and the <a href="http://tetra.osmocom.org/trac/wiki/osmo-tetra#Quickexample" target="_blank" rel="noopener noreferrer">HOWTO</a></td></tr><tr><td>airprobe</td><td>GSM sniffer</td><td>osmocom team et al</td><td><a href="http://git.gnumonks.org/cgi-bin/gitweb.cgi?p=airprobe.git" target="_blank" rel="noopener noreferrer">http://git.gnumonks.org/cgi-bin/gitweb.cgi?p=airprobe.git</a></td></tr><tr><td>gr-smartnet (WIP)</td><td>Trunking RX</td><td>Nick Foster</td><td><a href="http://www.reddit.com/r/RTLSDR/comments/us3yo/rtlsdr_smartnet/" target="_blank" rel="noopener noreferrer">http://www.reddit.com/r/RTLSDR/comments/us3yo/rtlsdr_smartnet/</a> <a href="http://www.reddit.com/r/RTLSDR/comments/vbxl0/attention_grsmartnet_users_or_attempted_users/" target="_blank" rel="noopener noreferrer">Notes from the author</a></td></tr><tr><td>gr-air-modes</td><td>ADS-B RX</td><td>Nick Foster</td><td><a href="https://www.cgran.org/wiki/gr-air-modes" target="_blank" rel="noopener noreferrer">https://www.cgran.org/wiki/gr-air-modes</a> call with --rtlsdr option</td></tr><tr><td>Linrad</td><td>SDR GUI</td><td>Leif Asbrink (SM5BSZ)</td><td><a href="http://www.nitehawk.com/sm5bsz/linuxdsp/hware/rtlsdr/rtlsdr.htm" target="_blank" rel="noopener noreferrer">http://www.nitehawk.com/sm5bsz/linuxdsp/hware/rtlsdr/rtlsdr.htm</a>" DAGC changes were applied to librtlsdr master</td></tr><tr><td>gr-ais (fork)</td><td>AIS RX</td><td>Nick Foster, Antoine Sirinelli, Christian Gagneraud</td><td><a href="https://github.com/chgans/gr-ais" target="_blank" rel="noopener noreferrer">https://github.com/chgans/gr-ais</a></td></tr><tr><td>GNSS-SDR</td><td>GPS RX (Realtime!)</td><td>Centre Tecnològic de elecomunicacions de Catalunya</td><td><a href="http://www.gnss-sdr.org/documentation/gnss-sdr-operation-realtek-rtl2832u-usb-dongle-dvb-t-receiver" target="_blank" rel="noopener noreferrer">Documentation</a> and <a href="http://www.gnss-sdr.org/" target="_blank" rel="noopener noreferrer">http://www.gnss-sdr.org/</a></td></tr><tr><td>LTE-Cell-Scanner</td><td>LTE Scanner / Tracker</td><td>James Peroulas, Evrytania LLC</td><td><a href="http://www.evrytania.com/lte-tools" target="_blank" rel="noopener noreferrer">http://www.evrytania.com/lte-tools</a> <a href="https://github.com/Evrytania/LTE-Cell-Scanner" target="_blank" rel="noopener noreferrer">https://github.com/Evrytania/LTE-Cell-Scanner</a>]</td></tr><tr><td>LTE-Cell-Scanner OpenCL accelerated <strong>(new)</strong></td><td>LTE Scanner / Tracker</td><td>Jiao Xianjun</td><td><a href="https://github.com/JiaoXianjun/LTE-Cell-Scanner" target="_blank" rel="noopener noreferrer">https://github.com/JiaoXianjun/LTE-Cell-Scanner</a></td></tr><tr><td>Simulink-RTL-SDR</td><td>MATLAB/Simulink wrapper</td><td>Michael Schwall, Sebastian Koslowski, Communication Engineering Lab (CEL), Karlsruhe Institute of Technology (KIT)</td><td><a href="http://www.cel.kit.edu/simulink_rtl_sdr.php" target="_blank" rel="noopener noreferrer">http://www.cel.kit.edu/simulink_rtl_sdr.php</a></td></tr><tr><td>gr-scan</td><td>Scanner</td><td>techmeology</td><td><a href="http://www.techmeology.co.uk/gr-scan/" target="_blank" rel="noopener noreferrer">http://www.techmeology.co.uk/gr-scan/</a></td></tr><tr><td>kalibrate-rtl</td><td>calibration tool</td><td>Joshua Lackey, Alexander Chemeris, Steve Markgraf</td><td><a href="https://github.com/steve-m/kalibrate-rtl" target="_blank" rel="noopener noreferrer">https://github.com/steve-m/kalibrate-rtl</a> <a href="http://rtlsdr.org/files/kalibrate-win-release.zip" target="_blank" rel="noopener noreferrer">Windows build</a></td></tr><tr><td>pocsag-mrt</td><td>Multichannel Realtime ]Decoder</td><td>iZsh</td><td><a href="https://github.com/iZsh/pocsag-mrt" target="_blank" rel="noopener noreferrer">https://github.com/iZsh/pocsag-mrt</a></td></tr><tr><td>adsb#</td><td>ADS-B RX</td><td>Youssef Touil, Ian Gilmour</td><td><a href="http://sdrsharp.com/index.php/a-simple-and-cheap-ads-b-receiver-using-rtl-sdr" target="_blank" rel="noopener noreferrer">http://sdrsharp.com/index.php/a-simple-and-cheap-ads-b-receiver-using-rtl-sdr</a></td></tr><tr><td>osmo-gmr-rtl</td><td>GMR1 RX</td><td>Dimitri Stolnikov</td><td><a href="https://osmocom.org/projects/gmr/wiki/GettingStarted#RTLSDRdongles" target="_blank" rel="noopener noreferrer">https://osmocom.org/projects/gmr/wiki/GettingStarted#RTLSDRdongles</a></td></tr><tr><td>rtl_adsb</td><td>ADS-B RX</td><td>Kyle Keen</td><td>comes with the library</td></tr><tr><td>dump1090</td><td>ADS-B RX</td><td>Salvatore Sanfilippo</td><td><a href="https://github.com/antirez/dump1090" target="_blank" rel="noopener noreferrer">https://github.com/antirez/dump1090</a></td></tr><tr><td>rtl_433</td><td>Temperature Sensor Receiver</td><td>Benjamin Larsson</td><td><a href="https://github.com/merbanan/rtl_433" target="_blank" rel="noopener noreferrer">https://github.com/merbanan/rtl_433</a></td></tr><tr><td>randio</td><td>Random number generator</td><td>Michel Pelletier</td><td><a href="https://github.com/michelp/randio" target="_blank" rel="noopener noreferrer">https://github.com/michelp/randio</a></td></tr><tr><td>gr-wmbus</td><td>m-bus (EN 13757-4) RX</td><td>oWCTejLVlFyNztcBnOoh</td><td><a href="https://github.com/oWCTejLVlFyNztcBnOoh/gr-wmbus" target="_blank" rel="noopener noreferrer">https://github.com/oWCTejLVlFyNztcBnOoh/gr-wmbus</a></td></tr><tr><td>ec3k</td><td>EnergyCount 3000 RX</td><td>Tomaž Šolc</td><td><a href="https://github.com/avian2/ec3k" target="_blank" rel="noopener noreferrer">https://github.com/avian2/ec3k</a></td></tr><tr><td>RTLSDR-Scanner</td><td>Radio Scanner</td><td>EarToEarOak</td><td><a href="https://github.com/EarToEarOak/RTLSDR-Scanner" target="_blank" rel="noopener noreferrer">https://github.com/EarToEarOak/RTLSDR-Scanner</a></td></tr><tr><td>simple_ra</td><td>Radio Astronomy App</td><td>Marcus Leech</td><td><a href="https://cgran.org/wiki/simple_ra" target="_blank" rel="noopener noreferrer">https://cgran.org/wiki/simple_ra</a></td></tr><tr><td>rtlizer</td><td>Spectrum analyzer</td><td>Alexandru Csete</td><td><a href="https://github.com/csete/rtlizer" target="_blank" rel="noopener noreferrer">https://github.com/csete/rtlizer</a></td></tr><tr><td>FS20_decode</td><td>FS20 Decoder</td><td>Thomas Frisch</td><td><a href="https://github.com/eT0M/rtl_sdr_FS20_decoder" target="_blank" rel="noopener noreferrer">https://github.com/eT0M/rtl_sdr_FS20_decoder</a></td></tr><tr><td>OpenLTE</td><td>LTE Toolkit</td><td>Ben Wojtowicz</td><td><a href="http://sourceforge.net/p/openlte/home/Home/" target="_blank" rel="noopener noreferrer">http://sourceforge.net/p/openlte/home/Home/</a></td></tr><tr><td>rtltcpaccess</td><td>DAB compatibility layer</td><td>Steve Markgraf</td><td><a href="https://github.com/steve-m/rtltcpaccess" target="_blank" rel="noopener noreferrer">https://github.com/steve-m/rtltcpaccess</a></td></tr><tr><td>SDR-J</td><td>"Analog" SDR &amp; DAB</td><td>Jan van Katwijk</td><td><a href="http://www.sdr-j.tk/" target="_blank" rel="noopener noreferrer">http://www.sdr-j.tk</a></td></tr><tr><td>RTLTcpSource</td><td>source for redhawk SDR framework</td><td>Michael Ihde</td><td><a href="http://redhawksdr.github.io/Documentation/" target="_blank" rel="noopener noreferrer">redhawk Docs page</a> <a href="https://github.com/Axios-Engineering/acquisition-components" target="_blank" rel="noopener noreferrer">RTLTcpSource</a></td></tr><tr><td>gortlsdr</td><td>Golang wrapper</td><td>Joseph Poirier</td><td><a href="https://github.com/jpoirier/gortlsdr" target="_blank" rel="noopener noreferrer">https://github.com/jpoirier/gortlsdr</a></td></tr><tr><td>gr-rds (fork)</td><td>RDS + WBFM receiver</td><td>Dimitrios Symeonidis et al</td><td><a href="https://github.com/bastibl/gr-rds" target="_blank" rel="noopener noreferrer">https://github.com/bastibl/gr-rds</a></td></tr><tr><td>NRF24-BTLE-Decoder</td><td>Decoder for 2.4 GHz NRF24 &amp; Bluetooh LE</td><td>Omri Iluz</td><td><a href="https://github.com/omriiluz/NRF24-BTLE-Decoder" target="_blank" rel="noopener noreferrer">Code</a> <a href="http://blog.cyberexplorer.me/2014/01/sniffing-and-decoding-nrf24l01-and.html" target="_blank" rel="noopener noreferrer">Blog post</a></td></tr><tr><td>acarsdec</td><td>ACARS decoder</td><td>Thierry Leconte</td><td><a href="http://sourceforge.net/projects/acarsdec/" target="_blank" rel="noopener noreferrer">http://sourceforge.net/projects/acarsdec/</a></td></tr><tr><td>rtl-sdr-airband</td><td>air band reiceiver/ATIS</td><td>Wong Man Hang</td><td><a href="https://github.com/microtony/RTLSDR-Airband" target="_blank" rel="noopener noreferrer">https://github.com/microtony/RTLSDR-Airband</a></td></tr></tbody></table>

Also take a look at the applications which use rtl-sdr [through gr-osmosdr](https://osmocom.org/projects/gr-osmosdr/wiki/GrOsmoSDR#KnownApps).

Using our lib? Tell us! Don't? Tell us why! :)

![spectrum view of GMR carriers](https://osmocom.org/attachments/download/2245/rtl-sdr-gmr.png "spectrum view of GMR carriers")  
Multiple GMR-carriers can be seen in a spectrum view with the full 3.2 MHz bandwidth (at 3.2 MS/s).

## Credits[¶](https://osmocom.org/projects/rtl-sdr/wiki#Credits)

rtl-sdr is developed by Steve Markgraf, Dimitri Stolnikov, and Hoernchen, with contributions by Kyle Keen, Christian Vogel and Harald Welte.