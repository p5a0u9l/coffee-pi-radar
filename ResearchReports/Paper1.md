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

A possible use case for an SDR could be one mounted on an unmanned platform operated remotely. The radar may start in an
active mode at a frequency suitable to long distance surveillance, trying to obtain a level of situational awareness. Then, possibly,
an airborne warning system arrives in theater to handle the situational awareness and the remotely-piloted aircraft (RPA) is tasked
to conduct passive operations. In this case, tuners used for transmitting are now switched to receive and the software changes
from active probing to passive listening, possibly using transmitters of opportunity as illuminators. Lastly, for whatever reason,
the radar is tasked with assuming an Electronic Attack role. In this case, most tuners are switched to transmit while only a few
receive. The software switches to a mode that actively acquires the parameters of the radar modes being used by adversarial radars
and begins to use jamming techniques to inhibit the threat's situational awareness.

It isn't hard to see the many strategic and cost advantages of re-configuring at will. The major of deployed radars, defense or
otherwise, are single purpose, active surveillance, passive surveillance, fire control, weapons guidance, Electronic Attack. Each
payload is an independant and expensive procurment.

### Cognitive Radar
In the case of software-defined radars (SDR), the command to change modes will come from an onboard or offboard operator
