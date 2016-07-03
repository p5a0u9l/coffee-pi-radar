## Coffee Can Real-Time Doppler Radar
#### Project for UW EE542 - Advanced Embedded Systems Design

### Overview

#### Motivation
Dr. Gregory Charvat _et al_ developed and documented a simple, yet powerful [laptop radar system](http://ocw.mit.edu/resources/res-ll-003-build-a-small-radar-system-capable-of-sensing-range-doppler-and-synthetic-aperture-radar-imaging-january-iap-2011/projects/MITRES_LL_003IAP11_proj_in.pdf) that uses coffee cans as Receive/Transmit Antennas.

I have wanted to have an excuse for trying this out, pairing it with a Raspberry Pi, instead of a laptop, and giving it some battery power to deploy in front of my house and record all the speed-limit busters! Similar projects have been implemented and provided at least a little direction for me,

- [Doppler Radar Explanation and Demo using the coffee can radar](https://www.youtube.com/watch?v=FOWopYv-JTM&list=PL60EBFF0DDA0145CA)
- [Build a Speed Camera and Traffic Logger on durablescope.com](http://blog.durablescope.com/post/BuildASpeedCameraAndTrafficLogger/)

This documentation will attempt to serve as a guide for duplicating and possibly extending my own effort.

#### Abstract

Doppler radar is an older technology that is finding renewed interest with modern computing hardware and software advances. It is widely used in applications like weather forecasting, law enforcement, aerospace, and healthcare. The technology exploits the Doppler effect to remotely capture data about a moving object's velocity. Additionally, system-on-a-chip technology is continually making it easier to deploy complicated embedded systems. This project will leverage the Cantenna Radar project developed by Dr. Gregory Charvat at MIT interfaced via a sound card to a Raspberry Pi to develop and deploy a simple, real-time Doppler Radar. The system will be used to measure, log, and analyze the speed of vehicles on a residential street over time.

#### Doppler Processing Playback

- Using the sample data from the [MIT opencourseware site](http://ocw.mit.edu/resources/res-ll-003-build-a-small-radar-system-capable-of-sensing-range-doppler-and-synthetic-aperture-radar-imaging-january-iap-2011/) I developed a visualization tool that demonstrates
real-time playback, peak-speed detection, and combines it with the sound file itself.

    * The upper subplot is a frequency view (transformed to speed in mph) of an average over 5 coherent integration periods, or "dwells". Each dwell is over 50 ms, and so the doppler spectrum being shown is over 250 ms, a 1/4 of a second. This seems a reasonable rate at which to track vehicle movement. Assuming, of course, the vehicle has negligible accelaration over this period.

    The red _*_ is the maximum value over the spectrum at that moment and is a reasonable estimate of the speed.

    * The lower subplot is an image of the same 250 ms period, but "seen from above". That is, the color/intensity values reflect the signal magnitude at that pixel. This image scrolls over time.

    [![Doppler Playbak](https://img.youtube.com/vi/JB-oInUjbWk/0.jpg)](https://www.youtube.com/watch?v=JB-oInUjbWk)

    * As reference, the full doppler image is included

![diagram](figs/doppler_image.png)

#### Block Diagram

![diagram](figs/block_diagram.png)

#### Schedule

- Proposal
    o 28-Jun-16 --> Complete

- Procurement
    * Order
        o 27-Jun-16 --> Complete
    * Receive
        o 04-Jul-16 --> Pending

- Physical Build
    * 05-Jul-16 --> Pending Parts

- RF --> IQ Testing
    * 12-Jul-16 --> Pending Build

- "R/T" Software Development
    * RPi initialized
        o 05-Jul-16
    * Buffer
        o 19-Jul-16
    * Frame-wise FFT
        o 19-Jul-16
    * Threshold Detection
        o 26-Jul-16
    * Report/Log
        o 26-Jul-16

- Analytic Software Development
    * TODO

#### Bill of Materials

see [bom](bom.txt)

    NOTE: Materials unique to this project are contained in the second table. For the first table, the more complete BOM in the above
    link is recommended. However, it should be noted (as I found out) that the table was compiled in 2011 and some of the part
    numbers are obsolete. Using the table description should hep find a suitable replacement.

