# Report Drafting
## Introduction
This project began as a conceived innovation to the MIT Coffee Can Radar [1], hereafter referred to as the reference design. The reference design demonstrated three different radar modes - Continuous-Wave (CW) Doppler, Frequency Modulated CW, and crude Synthetica Aperture Radar (SAR) - with minor hardware adjustments and using different processing algorithms. The system was interfaced with a laptop in order to acquire a block of data and then process the data offline and show results in Matlab. A block diagram is shown for reference.

![mit_block_diagram](figs/push.png)

Our goal was to implement two of these modes using streaming processing and human-in-the-loop mode switching, thus demonstrating a Software-Defined Radar (SDR) system. This project could be extended to interface the control software with waveform tuning hardware and demonstrate Cognitive Radar (CR).

Our initial innovation to the reference design was to design hardware improvements and add a real-time control loop with network offloading of results. The control portion was chosen to be implemented on a Raspberry Pi 2 running Arch Linux for ARM whereas the reference design interfaced with a laptop and used offline batch-mode processing. The modified high-level design is shown below for reference.

![our_block_diagram](figs/push.png)

## Discussion of Project
### Design Procedure
The SDR design can be summarized into two components: 1. The design improvements to the reference hardware system and 2. The software design.

#### Hardware Improvements
#### Software Design
The reference design provided Matlab scripts for ingesting a block of audio data and then processing to show results. There was no detection or tracking software included in this reference and neither did we attempt to develop sophisticated detection or tracking software. Rather, the data can be transformed and displayed as an image, which then allows the eye to perform the job of a target detector/tracker system.

Initial design began with experimenting with and rewriting the reference Matlab code to handle processing the data as a stream and displaying the results in a waterfall plot. This process was repeated for each of the two radar modes - Doppler and FMCW. These Matlab prototypes then became the reference point for developing Python on the Pi.

This process naturally led to the development of two tools which became essential throughout the development - software audio oscilliscope that plugged into various source data formats. Eventually this settled into one program used to pull various results from the Pi to my macbook and display the data in real-time on the laptop. The second program is similar except that is fetches data from either the disk or the sound card and performs some processing and then displays those results in a streaming fashion.

Finally, algorithms were migrated to Python on the Linux system and development proceeded over remote shell only. During this phase, publishing results to sockets that could be read from my laptop using the tool mentioned above was critical for testing and integration.

The design procedure relied on having the reference design as a starting point, signal processing knowledge, an understanding of the mathematics and physics involved, and the ability to iterate in rapid-prototyping environments like Matlab and Python until results agreed with expectations. We feel that this approach is suitable for research projects intending to demonstrate capability. While it is acknowledged that a more formal top-down methodology ensures success in a production environment, working in research and development, I have seen that creativity and persistence produce demonstration results quicker and cheaper than the process-oriented nature of production.

### System Description
#### Specification of the public interface
##### Inputs
##### Outputs
The Raspberry Pi does have the capability of running a desktop environment with graphics in order to display results, yet the overhead is significant and so the decision was made leave the Pi running in a headless manner and offload the resulting data over a local network to the development laptop for display. For test and debugging purposes, it was desirable to have the ability to visualize the data as it progressed throught the processing chain. The system output interface is visualized below.

![output interface](figs/pi_zmq_laptop_interface.png)

As seen, the program `netscope.m` takes a message name string for which a ZeroMQ socket is created which subscribes to that message type. The PUBLISH/SUBSCRIBE topology enables the Pi to artifically put all the data on the wire, yet only transfer the data that is requested. Matlab does not actually have a ZeroMQ implementation, yet it does expose a Python interface, through which ZeroMQ can be reached seamlessly.

In addition to the above the system also prints out status messages to the Raspberry Pi console.

Were the system to progress into a more productized instantiation, offloading reports could be achieved over a ZigBee link. Of course, this would limit the data rate to discrete detection measurements as opposed to the current toolset which allows viewing the data at any stage in the processing chain.

#### Algorithm Descriptions
##### Doppler CW
A Doppler CW system is able to measure the instantaneous radial velocity of a moving object. When an electromagnetic wave reflects off of a moving object, say a car, the wave is shifted in frequency by an amount proportional to the wavelength of the RF signal and the projection of the car's velocity onto the line from whence the wave originated. Doppler CW systems use a continuous sinusoid shifted to the carrier frequency. When the received signal is mixed with the transmitted signal, the difference is output. By performing a Fourier Transform on the received data, over some period of coherency, the radar is able to measure the magnitude response of the data at various frequencies. These are then related to speed using the wavelength.

##### Frequency Modulated CW (FMCW)
In FMCW, a triangle wave is generated rather than a sinusoid. When the triangle is passed through a voltage-controled oscillator (VCO) the ramp produces a linear frequency modulation (LFM) known as a chirp. This enables measurement of object distance from transmitter over the period of the ramp. As with Doppler, a frequency difference is measured and related to range by the speed of light and the bandwidth of the frequency ramp. However, for FMCW the coherent period is constrained to the period of the triangle ramp. Therefore, FMCW signals must be synchronized to the reference clock signal. This enables knowing the time the ramp was transmitted which can be differenced with the peak return in frequency for a measurement of distance.

Another difference is the dominance of stationary objects on the response spectrum. These are collectively referred to as clutter and reside at zero Hz (DC), though the energy bleeds into the nearby frequencies as well. If a radar is primarily interested in objects that move, clutter can be mitigated by taking a slow-time derivative of the data. Slow-time in that the time interval is measured in ramps instead of samples. By subtracting the previous respnse from the current response, much of the DC energy is removed and moving objects are left in the response. This clutter-mitigation strategy is known as a two-pulse canceller.

#### Timing constraints
For a sensor of any type, the time scale is ultimately driven by the kinematics of the objects of interest in the environment. At some point a simplification must be made and a period extablished over which it is assumed that the environment is stationary. For the case of our SDR, the objects of interest are of the human-walking and car-driving variety. Each of these is slow relative to airborne jets and so our time scale has some margin compared to typical radars.

If we assume the upper bound of stationarity to be a car moving at 35 m.p.h that translates to about 1 foot in 20 milliseconds and 5 feet in 100 milliseconds. Somewhere between 20 and 100 milliseconds we can reasonably assume our sensed environment is static. Our chirp ramps are tuned to last for 20 milliseconds, and so this becomes the fundamental unit of time for processing. Additionally, we can average over 1 to 5 of these pulses to smooth the output results and still have some confidence of the scene remaining roughly stable.

The other time constraint in this case is the ability of processing resources to handle the throughput requirements. Fortunately, the relatively slow speed of the objects of interest coupled with the fact that our system does not have the power to see beyond 1 km for a 10 square-meter target, means the information of interest is contained within a very narrow region of spectrum near DC. In fact, it is within the bandwidth of human auditory sensing. This pleasant coincidence results in an abundance of analog-to-digital converters with the requisite sample rates. This also means that our incoming data rate of 48000 samples/second is manageable for modern processor chips. Ultimately, required processing throughput depends on the data rate and the Raspberry Pi can handle a few audio signal processing operations within the required time frame.

#### Error handling
I will categorize the classes of errors as those which are induced by unexpected inputs, those induced by uncaught exceptions within the primary Python routine, and those induced by kernel scheduling, causing lag or loss of flow.

The first occur when the routine is unable to synchronize to the reference clock signal. This exception is caught by wrapping the sync block in a try/catch structure. If we are unable to sync, we want the routine to keep trying without falling apart. This reflects the software's inability to control external events, such as low battery power, fried circuits, or some other failure of the signal chain. Similarly, the routines downstream of sync need to predicate their execution on the indication from sync that everything is working. This is achieved with control flags once sync is achieved. Additionally, each pulse iteration checks the period of the sync interval to validate stability and throws a syncLost flag if sync is lost. Therefore, acquireSync is the initial state to which the routine returns if exceptions are encountered.

The second, exceptions within the main Python routine, are due to software bugs and unexpected corner cases. For our prototyping system, these are addressed using the built-in Linux kernel control wrapper called `systemd`. I will stress that when the input is operating correctly and the kernel is able to keep up with the data processing and throughput requirements, there have as yet not been uncaught errors within the main loop.

However, in order to handle the unexpected, three `systemd` unit modules were written to indicate what actions should be taken when one of the main programs crashes unexpectedly. The modules can be enabled as services which allow them be started automatically after a reboot once the kernel boot reaches the point where the device drivers have been intialized. Additionally, event actions can be specified, such as OnFailure or OnWatchdog. Precedence may be set such that program two waits until program one has successfully intitialized. In this way, we are leveraging the existing tool set within the wider Unix community to handle simple control flow and error handling. This is opposed to writing a custom routine to interact with the kernel scheduler. For a rapid-prototyped demonstrator, this reduces risk and cost. A produciton system might require more extensive effort to guarantee proper exception protocol and real-time scheduling priority.

This framework also enables handling the third failure mode where the kernel scheduling causes the audio server to fall behind resulting in audio discontinuities. In this case, the audio server, which is implemented using the third-party Jack library with ALSA as the device backend, is controlled by a custom `systemd` service which stops and restarts the server in the case where errors occurs due to overruns.

#### Hardware Implementation


#### Software Implementation


\newpage
## Code Listings

### Matlab Visualization Tools
\inputminted{matlab}{matlab/netscope.m}
\inputminted{matlab}{matlab/audioscope.m}
\inputminted{matlab}{matlab/imagr.m}

\newpage
### Matlab Algorithm Protyping
\inputminted{matlab}{matlab/batch_fmcw_detection.m}
\inputminted{matlab}{matlab/DopplerConfig.m}
\inputminted{matlab}{matlab/batch_doppler_example.m}
\inputminted{matlab}{matlab/run_event_doppler.m}
\inputminted{matlab}{matlab/event_doppler.m}

\newpage
### Python Main Programs
\inputminted{python}{serv-alsa.py}
\inputminted{python}{serv-fmcw.py}

\newpage
### Shell Scripts and systemd Modules
\inputminted{bash}{eth0-startup.sh}
\inputminted{bash}{kill-all.sh}
\inputminted{bash}{start-all.sh}
\inputminted{bash}{jackd.service}
\inputminted{bash}{serv-fmcw.service}
\inputminted{bash}{serv-alsa.service}
