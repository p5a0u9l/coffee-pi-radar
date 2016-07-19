# Cognitive Radar Survey
#### by Paul Adams and Lincoln Young

## Motivation

### Advanced Radar Catalysts

A simple picture of a radar includes a baseband to RF signal chain, starting with a given waveform and terminating in a radiating antenna, a receiving antenna, followed by an RF to baseband signal chain, and computing resources to process the signal, reduce the data, and extract useful information.

Over the years, the computing component has grown significantly, while the transmit/receive roles have shrunk to the bare neccessities. Most recently, radars have benefited from the advances in RF components largely due to market forces communications industry. Each new technology improves performance, reduces size, weight, power, or reduces schedule and cost - and, rarely, some combination of all three. A good example is the ability to implement baseband filtering in software.

Indeed, advances in computing have seen more and more of the front-end of the radar migrated into software. Functions like pulse-compression, beam-forming, filtering, that were purely hardware implementations in the past, are now almost exclusively performed in software. Of course, software is usually easier to change, upgrade and fix than hardware implementations. Similarly, the boom in wireless communications has pushed smaller and cheaper RF components that can be leveraged in radars as well.

Another improvement is clock stability which has become ubiquitous and pristine. The challenges once with phase coherency, uniform sampling, and coordination across devices running indepedant operating systems with indepedant clocks have been greatly reduced with the advent of crystal oscillators. Closely related to time precision is the universal usage of GPS and positional accuracy.  Clocks
that are already highly accurate in the short term can additionally be disciplined with a GPS pulse-per-second resulting in a global synchronization signal.

Every RF system that leverages computing requires an Analog-Digital Converter or Digital-Analog Converter or both. The sampling speed continues to improve and state-of-the-art systems can now sample at  about 2 GHz. The trend is pushing toward the ability to directly sample RF and do away with the traditional heterodyne receiver. The signal would go straight from an antenna/transducer, through an LNA and the ADC to the processing device, skipping the IF stage, with its mixers and filters, entirely. Of course, being able to sample up above X-band (~10 GHz) implies computing and data routing that can handle the massive bandwidth.


### Software-Defined Radar

A software-defined radar (SDR) is one where components like mixers, filters, and amplifiers are implemented on an FPGA, an embedded microchip or even a general purpose computer. A key feature of an SDR is the ability to reconfigure system operation with minimal or no hardware changes. As capability is migrated from analog to digital, increasing flexibility opens the door to radars that are capable of switching modes and/or waveforms based on scheduling or some control source - external or internal. Given an RF front-end with some flexibility in tuned frequency, polarity of elements (radiate, listen, or duplex), an antenna with a wideband response,
these changes can be dictated at the software level.

A possible use case for an SDR is now described to provide context. A radar system can be deployed on an unmanned platform operated remotely. The system may start in an active mode, emitting pulses into the environment, at a frequency suitable to long distance surveillance, seeking to obtain a level of situational awareness. Then, possibly, an airborne warning system arrives in theater and assumes the situational awareness role. At this time, the radar system is tasked with conducting passive operations. Tuners that had been used for transmitting are now switched to receive mode and the processing algorithms are changed from active probing to passive listening. Lastly, suppose the radar is tasked with assuming an Electronic Attack role. In this case, most tuners are switched to transmit while only a few receive. The software switches to a mode that actively acquires the parameters of the radar modes being used by adversarial emitters and begins to use jamming techniques to inhibit the threat's situational awareness.

It isn't difficult to imagine the many strategic and cost advantages of rapid reconfiguriion. The majority of deployed radars, defense or otherwise, are single purpose - active surveillance, passive surveillance, fire control, weapons guidance, Electronic Attack. Each payload is an independant and expensive procurement. The reuse and modularity leveraged in software development is often
a second thought as various vendors solve the same problems in various ways. Combining multiple missions on a single, flexible, upgradeable, system reduces cost and risk.

## Cognitive Radar

With the advent of flexible, software driven radar system architectures, the ability to apply real-time adaptation is increasingly within reach. Cognitive radar is not a new idea, but the techonological enablers have lacking to make implementation feasible. With the advances in the above mentioned sectioned, cognitive radar becomes more and more feasible.

In the case of SDR, the command to change modes will come from an onboard or offboard operator. The step beyond software radars is one that minimizes or removes the human in the loop. A Cognitive Radar is one that uses the information gained from sensing the environment to improve or adapt its mission according to a set of parameters.

Traditional radars have been configured in a mostly feed-forward sense, where there is no input from the controller to the radar. With some systems a radar operator may have the ability to change transmit parameters based on features seen on a display, but these are limited by response time and ability. Cognitive radars not only have feed-back central to their design, but are able to autonomously act upon the information and change configuration to optimize performance.

![diagram](figs/cog_diagram.png)

A well-known example from nature is bats using echolocation. will tune their sonar parameters as they close on their prey. They will start in
a surveillance mode, with high-doppler resolution, and lower range resolution. As they near the target, the pulse repetition
frequency changes to de-emphasize the doppler information and zero in on location.
