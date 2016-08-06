# Test Cases

## Testing Strategy

Developing on a headless system requires robust network access for debugging, deployment of code, and transfer of results for verification and visualization. Half of this is solved by using `ssh` remote login. In addition I wrote a python program that leverages ZeroMQ bindings to flexibly publish data from the raspberry pi to the local network. In this way, I can connect an application on my MacBook to the socket on the pi and pull down the raw audio data for visualization and debugging.

## Initialization Procedure

1. From the development laptop, open a terminal shell and log in to the raspberry pi over ssh.
    a. On my LAN the pi can be found via DHCP using the hostname `thebes`.
    b. Logging in through a new network requires a shell session using a monitor connected to the provided HDMI slot. Once logged in, you can authenticate with the wifi network being used using the command `wifi-menu`. At this point you can note the IP assigned to the pi and remote over `ssh` as normal.
    c. Note also that for security, password logins have been disabled and root logins are completely disabled. Authentication requires a copy of the ssh key generated for connecting to `thebes`.

2. Once logged in to the pi execute the python program `./streamr.py thebes stream sound`. At this point, any data entering the audio device buffers will be forwarded to ZeroMQ sockets over the network.

3. Back on the Development Laptop, in Matlab, execute the program
    scope('

## Test Plan

### Hardware

#### Function Generator Circuit

    - Verify the input to the VCO produces a triangle wave.
    - Verify the period of the triangle is adjustable using the Variable Rate Control input
    - Verify the signal bias varies as the Variable Voltage Control input is adjusted

#### Voltage Controlled Oscillator and RF Conditioning Circuit

