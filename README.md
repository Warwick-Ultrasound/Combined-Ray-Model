# Combined Ray Model

## Overview

This is a model of a V-mode clamp-on flow meter. It uses ray tracing with many rays originating from the generation piezoelectric to model the whole beam. As it tracks a ray through the system, it accounts for the amplitude and phase changes at material interfaces, attenuation in the different materials, beam spread, and the fluid flow in the pipe. The interaction with the fluid is the key difference between this model and other ray-based models - it uses the small but significant deflection of the ultrasonic beam at low flows to introduce the dependence on flow as introduced by FLEXIM [1], but allows for flow profiles to be specified that are not uniform.

This README will first go over some of the key information about the model. Then, a description of the MAIN scripts and their purpose will be provided. Finally, a description of the back end will be provided in case you need to modify anything. 

---
### Key Information

- The model allows for a maximum of two transits through the upper pipe wall and two in the bottom wall. The path that a particular ray has taken through the system is indicated by a 4-letter string, indicating the wave mode in each wall transit, in the order that the ultrasound encounters them. For example, LSSL is a path which is longitudinal in both top wall transits and shear in both bottom wall transits. SNNS is a path which is shear in both top wall transits and does not enter the bottom wall, since it reflects off the inner surface of the pipe.

- It is assumed that attenuation increases linearly with frequency. This is a good approximation for polymers, where the attenuation will be most significant. This can be changed by modifying the 'attenuation.m' function if necessary.

- The boundaries are modelled via the theory in [2] and [3]. The theory in [2] is for a 'rigid' boundary, where motion parallel to the interface is transmitted. For a 'slip' boundary, which does not transmit motion parallel to the boundary, the theory in [3] is used. All boundaries involving a fluid as one of the media are considered rigid, despite not supporting shear stresses - it's really a description of the boundary physics rather than the waves that are formed. For the transducer-pipe boundary, the user may select 'slip' or 'rigid' depending on how their transducers are attached to the pipe. The 'slip' option will be more appropriate for gel couplants, and the rigid is applicable if the transducers are rigidly bonded to the pipe, or a very thin layer of highly viscous couplant is used.

- Rather that swapping the roles of the transducers to generate upstream/downstream pairs of signals, the model flips the flow direction. This is equivalent but is much less cumbersome to implement.

- In all of the MAIN scripts which have multiple rays coming from the generation piezoelectric, there are two parameters to control the fan of rays that are generated: N_perp is the number of points along the piezoelectric that have rays coming from them, and N_ang is the number of rays in the fan located at each point.

[1] O. Keitmann-Curdes, B. Funck, A new calibration method for ultrasonic clamp-on transducers, in: 2008 IEEE Ultrasonics Symposium, 2008, pp. 517–520. doi:10.1109/ULTSYM.2008.0125.

[2] J. L. Rose, Oblique Incidence, Cambridge University Press, 2014, Ch. 5, pp. 67–75.

[3] G. J. Kuhn, A. Lutsch, Elastic Wave Mode Conversion at a Solid-Solid Boundary with Transverse Slip, The Journal of the Acoustical Society of America 33 (7) (2005) 949–954. doi:10.1121/1.1908861.

---
## MAIN Scripts

A selection of main scripts have been provided which investigate different aspects of the clamp-on meter. 

### materials

The materials script defines all of the materials that can be used in the models. Each material is a struct with fields:

- clong: the longitudinal speed of sound
- cshear: the shear speed of sound (solids only)
- rho: mass density
- G: shear modulus (can be calculated using rho*cshear^2) (solids only)
- alphaLong: longitudinal attenuation coefficient (dB/m)
- alphaShear: shear attenuation coefficient (dB/m)
- alphaf0: the frequency at which the provided attenuation values were measured

The attenuation parameters are optional, but attenuation in the material will only be considered if they are entered. It is particularly important to input attenuation data for plastic pipes, because they usually attenuate shear more than longitudinal and this is likely to change the outcome of the model. 

### MAIN_singleRayCorrectionFactor

This script tracks a single ray path through the system and uses it to calculate the hydraulic correction factor for the inputted flow profile. The user inputs the path key (4-letter string describing the path to use) and the script tracks the ray through the system at a low flow rate. It detects where the ray intersects with the reception piezoelectric for the upstream and downstream bursts, then measures the difference in their transit distances and hence the transit time difference (TTD) that is measured. It then uses the usual equation for the flow rate to find the TTD that would be measured in plug flow, and takes the ratio to find the correction factor. 

This approach uses the intersection points directly rather than relying on the computed signals to reduce the computational error introduced.

### MAIN_FlowRateScan

Places the transducer in the right location for the path provided on line 32, then scans the flow rate through the provided values and measures the TTD. The output is a plot of the TTD as a function of flow rate, with the conventional theoretical TTD plotted over the top for plug flow. This script will also output the correction factor, but it will be less accurate than the singleRayCorrectionFactor script at obtaining the 'conventional' values due to computational error.

### MAIN_transducerPositionScan

The purpose of this script is to tell you which paths the ultrasound is taking to create the received signal as a function of transducer separation. It scans the transducer position between two values in small steps. At each one, it calculates all of the rays that intercept with the reception piezoelectric and sums the waveforms from each type of path (e.g. all of the LNNL waveforms get summed). It measures the amplitude of each of these contributions, then sums all of the waveforms and measures the amplitude of the total received signal. It will then plot these metrics as a function of transducer separation, resulting in a plot which tells you which paths ultrasound is taking.

### MAIN_wallThicknessScan

This script fixes the OD of the pipe and scans the wall thickness between two predefined values. At each wall thickness, it places the transducers to receive the SNNS path and measures the signal contributions from the LNNL and SNNS paths. Then it repeats the same calculation at the correct position for the LNNL path. It also measures the TTD at both locations and uses them to calculate the error introduced by having the transducers in the wrong location. It plots the error as a function of pipe wall thickness.

---
## Back End

The following is a brief description of the purpose of each function in the back end to give an idea of how the model works. First, the various data structures that are used will be laid out, then the functions which transform them will be detailed. Further information can be found in each of the functions, which are commented and should be relatively readable.

### Data Structures

**path structure**

A path is a struct which represents a complete path through the system from one transducer to the other (or it might miss). It has fields:
- rays: Another struct showing the exact path the meter took through the system (see below)
- detected: A bool showing whether or not the path intersects with the reception piezoelectric
- burst: An array containing the ultrasonic signal contribution from that path
- time: The corresponding time array
- pathKey: The 4-letter path type identifier string
- x0: The x-coordinate at which the path started on the generation piezoelectric
- pk_pk: The peak-to-peak amplitude of the burst field

**rays**

A cell array, with each cell containing the transit through a single material in the form of a single "ray" struct.

**ray**

A struct containing a single transit through a single material. These are stacked into 'rays' cell arrays, then into paths structs to map out a full path. A ray has fields:
- start: the starting location of the ray
- eq: A function handle for the equation of the ray
- stop: the end point of the ray
- material: A struct from the materials script containing all of the material parameters for the medium the ray travels through
- type: 'L' or 'S' for longitudinal or shear
For a ray in the water, the path is curved. So, rather than specifying a function handle 'eq', a field called 'coords' is specified which contains the x, y coordinates of the path.

**materials**

A struct containing all of the materials information for the model. It has fields:
- pipe: material struct for pipe material
- transducer: The same for the transducer wedge material
- fluid: Same again for fluid
- outside: material that is outside the meter, usually air
- coupling: can be 'rigid' or 'slip' - see description of boundaries above

**gInp**

This is the geometry input struct, which is used to create an internal geometry object which maps out all of the meter boundaries. It has fields:
- R: internal pipe radius
- thick: wall thickness
- thetaT: transducer wedge angle (angle of incidence into pipe wall)
- hp: height of the centre point of the piezoelectric above pipe wall
- Lp: length of piezoelectric
- sep: transducer separation. Measured between piezo centre points

**geom**

An internally generated struct which contains all of the information required to run the model. It contains the boundaries in the internal coordinate system from gInp using the function genGeometry. It has fields:
- pipeExtTop: y-location of exterior of top wall
- pipeIntTop: y-location of interior of top wall
- pipeIntBot: y-location of interior of bottom wall
- pipeExtBot: y-location of exterior of bottom wall
- R: interior radius
- piezoLeftCentre: left piezo centre coordinates
- piezoRightCentre: right piezo centre coordinates
- piezoLeft: equation of line going along left piezo
- piezoRight: equation of line going along right piezo
- piezoLeftBounds: A struct with x and y fields containing the endpoints of the left piezo
- piezoRightBounds: A struct with x and y fields containing the endpoints of the right piezo
- thetaT: the transducer wedge angle

**flow**

A struct representing the flow through the pipe. Has fields:
- profile: a function handle for generating the local velocity at a point in the pipe
- v_ave: average velocity ver the pipe cross-section
- N: how many points to sample at during each transit through the fluid
- n: The order of the turbulent profile. If not using, set it to any number

**burst**

A struct representing the ultrasonic burst at the start of the simulation. It is generated by genBurst. It contains fields:
- t: the time array
- y: the amplitude values
- f0: centre frequency
- BW: bandwidth percentage (as defined below in genBurst)

### Back End Functions

**c_PEEK, c_PEEK_shear, c_water**

These functions take the temperature in degrees Celsius and return the speed of sound in PEEK or water as per the function name.

**plug, laminar, turbulent, zero**

These are functions which represent the different flow profiles that can be used. They take as arguments:
- r: radial coordinate (number or array)
- R: internal radius of pipe
- v_ave: average flow velocity over pipe cross-section
- n: turbulent profile order
They return a vector the same size as r containing the flow velocity at the requested radial coordinates.

**LSboundary, SLboundary, SSrigid, SSslip**

These functions perform the calculations to work out the effects of the different boundaries in the system on the ray and the signal. The first letter is medium 1, 2nd letter is medium 2. The SS boundary has two options: one for the slip boundary condition and one for the rigid boundary condition. They take as arguments:
- m1: medium 1, specified as a material struct
- m2: medium 2, specified as a material struct
- theta0: the angle of incidence into the boundary
- f: the centre frequency of the inbound wave
- inType: 'L' or 'S' to indicate longitudinal or shear incidence
The output is [A, theta], where:
- A: A vector of amplitudes if the incidence amplitude was 1. [RL, RS, TL, TS] where R = reflected, T = transmitted, L = longitudinal, S = shear
- theta: Angles of reflection/refraction in the same order as A

**genBurst**

Generates a wave burst to represent the wave emitted from the generation piezoelectric. All rays will start with this burst before the modifications are applied as they travel through the system. It takes inputs:
- t: the time array
- f0: centre frequency of burst
- BW: percentage bandwidth (NOTE: this si not the FWHM of the spectrum, but the full window width of a hanging window in the frequency domain)
The output is a burst struct containing the burst information.

**genGeometry**

Takes the geometry input struct and calculates the geometry of the entire meter. Returns a geom struct.

**transducerPositionCalc**

Calculates the transducer separation that would expect to use for a particular path through the system. Takes as inputs:
- gInp: the geometry input struct
- mat: the materials struct
- pathKey: a 4-letter string describing the path that should be used to calculate the separation
It then outputs the transducer separation.

**genBeam**

Calculates parameters describing the ultrasonic beam so that the rest of the model knows which rays to simulate. The inputs are:
- g: geometry struct
- mat: materials struct
- B: burst struct
- Nperp: number of locations along piezo to place rays at
- Nang: number of rays in the fan at each of the Nperp locations
Returns:
- x0: x-locations of ray starting positions
- dtheta: deflection angles from the piezo-normal
- A: relative amplitudes of starting rays (currently just set to ones, but can implement if needed)

**genRay**

Used for generating the rays coming from the generation piezoelectric. Takes as inputs:
- g: geometry struct
- mat: materials struct
- x0: x-location at which to start the ray
- dtheta: deflection angle away from the piezo-normal (optional, defaults to zero)
Outputs a ray struct representing the first ray in the path

**genArbRay**

Used to generate a ray starting at any location with a given angle to the vertical. This function is used internally to generate almost all of the rays through the system. The inputs are:
- startCoords: (x,y) containing starting coordinates of ray
- theta: angle to vertical
- type: 'L' or 'S' for longitudinal or shear wave ray
- material: material struct for the material the ray is in
- g: geometry struct
- nextBound: string representing the name of the next boundary you expect the ray to encounter for calculation of the endpoint. Valid options are:
    - pipeExtTop: top wall, exterior surface
    - pipeIntTop: top wall, interior surface
    - pipeIntBot: bottom wall, interior surface
    - pipeExtBot: bottom wall, exterior surface
    - piezoRight: the reception piezoelectric
The output is the requested ray structure

**transit**

A function which modifies a burst to simulate the effect of transiting through a given material, including both the time delay and attenuation (if parameters inputted). It operates in the frequency domain and is called multiple times, so rather than inputting and outputting time domain signals it just leaves everything in the frequency domain for speed. The inputs are:
- ray: ray struct for the section of path that the ultrasound is travelling through
- freq: the frequency array of the spectrum
- spect: the spectrum of the signal to modify
The output is a modified spectrum.

**impossiblePath**

Returns a path structure that indicates internally that the path requested is not possible. This could be, for example, because the angle of incidence is beyond the critical angle. The inputs are:
- time: the time array
- pathKey: the 4-letter path descriptor
- Nrays: the number of rays that should be in the path
- x0: the x-location that the first ray started at
The output is a path struct in which each ray is set to nan, the detected property is false, and the burst and peak-to-peak properties are set to zero. This means it cannot be counted in anything going forward.

**calcFluidRay**

Generates the curved ray through the fluid given a flow profile. The inputs are:
- startCoords: the coordinates at which the ray enters the fluid
- theta0: angle of refraction into stationary water
- flow: flow struct
- g: geometry struct
- mat: materials struct
- n: (optional) turbulent profile order
The output is the ray that gets added to the path struct.

**createPath**

Generates a path through the system given the inputs and returns the path struct. The inputs are:
- g: geometry struct
- mat: materials struct
- x0: starting x-location on generation piezo
- pathKey: identifies which path ultrasound should take
- B: burst struct
- flow: flow struct
- dtheta: angle of deflection of ray from piezo normal (optional, defaults to zero)
The output is the path struct.

**genAllPaths**

From a single ray at the generation piezo, there are 16 possible paths through the system represented by the 16 possible path keys. This function iterates createPath to generate all 16 paths, and then returns them. The inputs are:
- g: geometry struct
- mat: materials struct
- x0: x-location ray should start at on generation piezo
- B: burst struct
- flow: flow struct
- dtheta: ray deflection angle from normal (optional, defaults to zero)
Outputs the paths struct containing all 16 possible paths through the system

**receivedSignal**

After all paths through the system have been calculated, this function can be used to sum all of the ultrasonic bursts that intersect with the reception piezoelectric to obtain the signal that would be measured. The inputs are:
- paths: A cell array, where each cell is a path through the system that you want to include in the sum. Can be any size in 2D.
Outputs are in the form [signal, detectionPoints, A], where:
- signal: the received signal
- detectionPoints: 2xN array of (x,y) coordinates showing where on the piezo rays intersected with it. Used mainly for debugging.
- A: array of peak-to-peak amplitudes of each ray which contributes

**receivedSignalHist**

Takes the 'A' output from receivedSIgnal and uses it to construct a histogram. The piezo is split into bins along its length, then the waves that intersect inside each bin are summed, and the peak-to-peak amplitude is measured. Useful to see where on the piezo most of the energy is being received if the transducer is not located optimally. The inputs are:
- g: geometry struct
- detPoints: detectionPoints output from receivedSignal
- Arec: A output from receivedSignal
- Nbins: Number of bins to split piezo into along its length
Outputs:
- Abinned: The amplitude incident on each bin
- edges: the length along the piezo at the edges of each bin
These outputs can be put into the histogram function to plot the data.

**pathAnalyser**

Runs through all of the possible paths in a cell array of paths and adds up the waves from all rays of a single path key. It then takes the peak-to-peak amplitude, and moves on to the next pathKey, until it has been through them all. This provides insight into which route through the system energy is taking, and how it all adds up to give you the signal you see. The inputs are:
- paths: the cell array of path structs
- display: 1 or 0: 1 displays a bar graph of the results, 0 doesn't
Outputs:
pathKeys: the path keys corresponding to the different routes through the system
pkpk: an array of the peak-to-peak amplitudes of each of the different routes through the system when they reach the reception transducer

**drawGeometry**

Creates a new figure and draws lines representing the pipe walls and the piezoelectric elements. This creates a base on top of which rays can be drawn. The inputs are:
- g: geometry struct
- newFig: set to 'off' to not create a new figure. Defaults to on. (optional)

**drawRay**

Draws a single ray (in one material) on top of the geometry figure created using drawGeometry. Inputs are:
- ray: the ray struct
- lineSpec: lineSpec as inputted to MATLABs plot function to format line. e.g. 'b-' for a blue solid line.

**drawPath**

Iterates drawRay over a path struct to draw out a whole path. Uses blue lines for longitudinal and red for shear. Inputs are:
- path: the path struct

**drawAllPaths**

Takes the cell array containing all paths and iterates through it, drawing them all. The input can be 1D or 2D. Inputs:
- paths: the cell array containing one path per cell

**arrival_detect**

Takes an ultrasonic signal and finds the arrivals, then returns the starting and stopping indices so that they can be cropped out of the array. Inputs are:
- volts: the y-coordinate array of the ultrasonic signal
- N_arrivals: The number of arrivals to find
Outputs [starts, stops, envelope]:
- starts: an array of indices indicating the starting points of the N_arrivals arrivals of ultrasound
- stops: the corresponding end points of the arrivals
- envelope: the envelope of the input signal (normalised). This is part of how the function works so this is a debugging tool in case it doesn't select the arrivals you wanted

**flow_process_SG_filt**

Takes a pair of ultrasonic signals, potentially containing multiple arrivals in each, and measures the transit time differences. The inputs are:
- upvolts: the upstream signal
- downvolts: the downstream signal
- time: the time array
- N_interp: the factor by which the number of points in the signals is increased before cross-correlation
- starts: arrival start indices from arrival_detect
- stops: arrival end indices from arrival_detect
Outputs:
- dts: an array of time differences, one per arrival
- pkpk: an array containing the peak to peak amplitudes of each of the arrivals
