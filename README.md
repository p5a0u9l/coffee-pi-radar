## Coffee Can Real-Time Doppler Radar
#### Project for UW EE542 - Advanced Embedded Systems Design

### Overview

#### Motivation
Dr. Gregory Charvat _et al_ developed and documented a simple, yet powerful [laptop radar system](http://ocw.mit.edu/resources/res-ll-003-build-a-small-radar-system-capable-of-sensing-range-doppler-and-synthetic-aperture-radar-imaging-january-iap-2011/projects/MITRES_LL_003IAP11_proj_in.pdf) that uses coffee cans as Receive/Transmit Antennas.

I have wanted to have an excuse for trying this out, pairing it with a Raspberry Pi, instead of a laptop, and giving it some battery power to deploy in front of my house and record all the speed-limit busters! Similar projects have been tried, notably

    - [link]()
    - [link]()

This documentation will attempt to serve as a guide for duplicating and possibly extending this effort.

#### Abstract

Doppler radar is an older technology that is finding renewed interest with modern computing hardware and software advances. It is widely used in applications like weather forecasting, law enforcement, aerospace, and healthcare. The technology exploits the Doppler effect to remotely capture data about a moving object's velocity. Additionally, system-on-a-chip technology is continually making it easier to deploy complicated embedded systems. This project will leverage the Cantenna Radar project developed by Dr. Gregory Charvat at MIT interfaced via a sound card to a Raspberry Pi to develop and deploy a simple, real-time Doppler Radar. The system will be used to measure, log, and analyze the speed of vehicles on a residential street over time.

#### Bill of Materials

see [bom](bom.txt)

    NOTE: Materials unique to this project are contained in the second table. For the first table, the more complete BOM in the above
    link is recommended. However, it should be noted (as I found out) that the table was compiled in 2011 and some of the part
    numbers are obsolete. Using the table description should hep find a suitable replacement.

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

