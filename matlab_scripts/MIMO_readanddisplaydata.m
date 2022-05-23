clear all
close all
clc

%% Open and Read Data File
filename = '25frames_30mhzslope_10mhzsample';
fid = fopen(append(filename,'.bin'),'r'); % open binary file

%% set parameters
% these parameters are set in the radar
nChirps=128; % number of chirps
adcSamples=256; % number of ADC samples per chirp
nFrames = 25; % number of frames, each frame is nChirps * adcSamples
rawData=fread(fid,'uint16'); % read the file
rawData=rawData-2^15; % 2's compliments correction, defined in radar
S = 30e12; % slope
Fs = 10e6; % sample rate
freq = 77e9; % center frequency
carrierFreq = freq + (adcSamples/Fs*S)/2; % carrier frequency
Tc = 8.4e-6; %time between chirp
c = 299792458; %speed of light in m/s
pulseRepetitionFrequency = 1/((adcSamples/Fs + Tc)*2); % PRF

%% arrangement of raw data into I+jQ format
idx=1; 

for i = 1:2:numel(rawData)
    
    rawIQ(idx,1) = rawData(i)+1i*rawData(i+1);
    idx = idx+1;
end

clear rawData

% reshaping the data into nAntenna*nSamples*nChirps*nFrames
rawIQ = reshape(rawIQ,4,adcSamples*2,nChirps,nFrames);


%% arranging the data for virtual array (MIMO Mode)
rawIQ_Varray = zeros(4*2,adcSamples,nChirps,nFrames);
for j=1:nFrames % repeat the process for all antennas and frames
    for i=1:4
        rawIQ_Varray(i,:,:,:) = rawIQ(i,1:adcSamples,:,:);
        rawIQ_Varray(i+4,:,:,:) = rawIQ(i,adcSamples+1:end,:,:);
    end
end

fclose(fid);
clear rawIQ
%% Phased Array Toolbox for Range Doppler Response

H = phased.RangeDopplerResponse(...
    'DopplerOutput','Speed',...
    'RangeMethod','FFT',...
    'PRFSource', 'Property',...
    'PRF',pulseRepetitionFrequency,...
    'OperatingFrequency',carrierFreq,...
    'DopplerWindow','Hann',...
    'RangeWindow','Hann',...
    'SampleRate',Fs,...
    'SweepSlope',S);

X = permute(rawIQ_Varray,[2 1 3 4]); % rearrange into samples,antennas,chirps,frames

% Plot antenna 1, frame 1 as an example
plotResponse(H,squeeze(X(:,1,:,1)),'Unit','db');
colormap jet;

fclose('all');