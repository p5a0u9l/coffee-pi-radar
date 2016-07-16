# Cognitive Radar Survey
#### by Paul Adams and Lincoln Young

## Motivation
### Advanced Radar Catalysts

A simple picture of a radar includes a transmitting baseband to RF signal chain, starting with a given waveform and terminating in a radiating antenna, a receiving antenna, followed by an RF to baseband signal chain, and computing resources to process the signal, reduce the data, and generate useful information.

Over the years, the computing component has grown exponentially, while the transmit/receive roles have shrunk to the bare neccessities. They have most recently benefited from the advances in RF components largely due to the communications industry. Each new technology improves performance, or reduces Size, Weight, Power, or reduces schedule and cost - and, rarely, some combination of all three.

Advances in computing have seen more and more of the front-end of the radar migrated into software. Functions like pulse-compression, beam-forming, filtering, that were purely hardware implementations in the past, are now almost exclusively performed in software. Of course, software is usually easier to change, upgrade and fix than hardware implementations. Similarly, the boom in wireless communications has pushed smaller and cheaper RF components that can be leveraged in radars as well.

Clock stability has become ubiquitous and pristine greatly reducing challenges associated with things like short-time phase coherency, uniform sampling, and coordination across devices running indepedant operating systems with indepedant clocks. Closely related is the universal usage of GPS and positional accuracy.

Every RF system that leverages computing requires an Analog-Digital Converter or Digital-Analog Converter or both. The sampling speed continues to improve and state-of-the-art systems can sample at ~2 GHz. The trend is pushing toward the ability to directly sample RF and do away with the traditional heterodyne receiver. The signal could go straight from the antenna/transducer, through an LNA and the ADC to the processing device, skipping the IF stage, with it's mixers and filters, entirely. Of course, being able to sample up above X-band (~10 GHz) implies computing and data routing that can handle the massive bandwidth.


### Software-Defined Radar

As capability is migrated from the world of analog to that of digital, increasing flexibility opens the door to radars that are capable of switching modes and/or waveforms based on scheduling or some control source - external or internal. Given an RF front-end with some flexibility in tuned frequency, polarity of elements (radiate, listen, or duplex), an antenna with a wideband response, these changes can be dictated at the software level.

### Cognitive Radar
In the case of software-defined radars (SDR), the command to change modes will come from an onboard or offboard operator
