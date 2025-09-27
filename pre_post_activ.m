close all;
clear;
clc;
%% Read the data
raw_data = xlsread('adinevand.land2.xlsx');
FZ = raw_data(:,11);   % Vertical ground reaction force (Fz)

%% Sampling info
samplingRateHz = 1000;            
numSamples = numel(FZ);
timeVectorSec = (0:numSamples-1) / samplingRateHz;

%% finding the weight in the first stable phase after landing, it can be done with drawing the plot also
% Find the main (largest) peak in vertical force
[peakValues, peakLocations] = findpeaks(FZ, 'MinPeakHeight', 500);
if isempty(peakLocations)
    error('No peaks found. Adjust MinPeakHeight threshold.');
end
[~, indexOfMainPeak] = max(peakValues);    
mainPeakIndex = peakLocations(indexOfMainPeak);

% Compute absolute derivative of vertical force
forceDerivativeAbs = abs(diff(FZ));

% Parameters for stability detection
stabilityThreshold = 100;           % Threshold for "small change" in force
minStableSamples = samplingRateHz * 0.5;   % 0.5 seconds = 500 samples

% Search region: only after the main peak (+0.2s)
searchStartIndex = mainPeakIndex + round(samplingRateHz * 0.2);
searchEndIndex   = numSamples - 1;
isStableSample = forceDerivativeAbs < stabilityThreshold;

% Find the first stable stretch
consecutiveStableCount = 0;
stableStartIndex = NaN; 
stableEndIndex = NaN;

for i = searchStartIndex:searchEndIndex
    if isStableSample(i)
        consecutiveStableCount = consecutiveStableCount + 1;
        if consecutiveStableCount >= minStableSamples
            stableEndIndex = i;
            stableStartIndex = i - minStableSamples + 1;
            break;
        end
    else
        consecutiveStableCount = 0;
    end
end

% Compute body weight in stable window
if ~isnan(stableStartIndex)
    stableForceSegment = FZ(stableStartIndex:stableEndIndex);
    bodyWeightNewton = mean(stableForceSegment);
    bodyMassKg = bodyWeightNewton / 9.81;

    fprintf('Estimated body weight = %.2f N (%.2f kg)\n', ...
        bodyWeightNewton, bodyMassKg);
else
    warning('No stable window found. Try adjusting stabilityThreshold or minStableSamples.');
end

% Plot result with highlighted stable phase
figure;
plot(timeVectorSec, FZ, 'b', 'LineWidth', 1); hold on;

if ~isnan(stableStartIndex)
    % Highlight stable phase as a green patch
    fill([timeVectorSec(stableStartIndex) timeVectorSec(stableEndIndex) ...
          timeVectorSec(stableEndIndex) timeVectorSec(stableStartIndex)], ...
         [min(FZ) min(FZ) ...
          max(FZ) max(FZ)], ...
         [0.8 1 0.8], 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    % Add vertical lines for clarity
    xline(stableStartIndex/samplingRateHz, 'g--', 'Stable Start');
    xline(stableEndIndex/samplingRateHz, 'g--', 'Stable End');
end

xlabel('Time (s)');
ylabel('Vertical GRF (N)');
title('Stable Standing Window Detection + Body Weight Calculation');
grid on;
%% since force data starts from 0 there is no need for base line correction 

%% filtering data
%% Low-pass filter (Butterworth, 4th order, cutoff 50 Hz)
filterOrder = 4;
cutoffFreq = 50;                % Hz
Wn = cutoffFreq / (samplingRateHz/2);       % normalized cutoff frequency
[b, a] = butter(filterOrder, Wn, 'low');

FZ_filtered = filtfilt(b, a, FZ);

%% Plot raw vs filtered
figure;
plot(timeVectorSec, FZ, 'b', 'DisplayName', 'Raw Fz'); hold on;
plot(timeVectorSec, FZ_filtered, 'r', 'LineWidth', 1.2, 'DisplayName', 'Filtered Fz (50 Hz)');
xlabel('Time (s)');
ylabel('Vertical GRF (N)');
title('Vertical Force: Raw vs Low-pass Filtered');
legend;
grid on;
%% Threshold definition
thresholdNewton = 0.10 * bodyWeightNewton;   % 10% body weight

%% Event detection: contact on and off
isAboveThreshold = FZ_filtered > thresholdNewton;

% Find rising edges (contact onset)
contactOnIndices = find(diff(isAboveThreshold) == 1) + 1;
% Find falling edges (contact offset)
contactOffIndices = find(diff(isAboveThreshold) == -1) + 1;

% Stability condition (>=20 ms)
minContactSamples = round(0.02 * samplingRateHz);
validContacts = [];
validOffsets  = [];

for k = 1:length(contactOnIndices)
    onIdx = contactOnIndices(k);
    % Find the next offset after this onset
    offIdx = contactOffIndices(find(contactOffIndices > onIdx, 1));
    if ~isempty(offIdx) && (offIdx - onIdx) >= minContactSamples
        validContacts(end+1) = onIdx;
        validOffsets(end+1)  = offIdx;
    end
end

%% Convert to time (seconds)
contactOnTimes  = validContacts / samplingRateHz;
contactOffTimes = validOffsets  / samplingRateHz;

%% Display results
disp('Contact events (samples and seconds):');
for k = 1:length(validContacts)
    fprintf('Contact %d: On = %d samples (%.3f s), Off = %d samples (%.3f s)\n', ...
        k, validContacts(k), contactOnTimes(k), ...
        validOffsets(k),  contactOffTimes(k));
end

%% Plot with events marked
figure;
plot(timeVectorSec, FZ_filtered, 'b'); hold on;
yline(thresholdNewton, 'r--', 'Threshold');

for k = 1:length(validContacts)
    xline(contactOnTimes(k),  'g--', 'Contact On');
    xline(contactOffTimes(k), 'm--', 'Contact Off');
end

xlabel('Time (s)');
ylabel('Vertical GRF (N)');
title('Event Detection: Contact On/Off');
grid on;
%% ===== EMG processing and onset/offset detection =====
% Assumptions:
% - samplingRateHz, timeVectorSec, and contact times (validContacts/validOffsets or contactOnTimes/OffTimes)
%   are already computed from the Fz pipeline.
% - EMG raw channel is in column 2 of the same Excel file.

%% Read EMG (if not already in workspace)
EMG_raw = raw_data(:,2);   % raw EMG channel
%% Step 1: Baseline correction (remove bias)
emg_mean = mean(EMG_raw);
emg_corrected = EMG_raw - emg_mean;
%% Step 2: Band-pass filter for EMG
fs = 1000;              % corrected to 1000 Hz
lowCut = 20;            % High-pass cutoff (Hz)
highCut = 400;          % Low-pass cutoff (Hz)

[b,a] = butter(4, [lowCut highCut] / (fs/2), 'bandpass');
emg_filtered = filtfilt(b,a, emg_corrected);   % <-- ONLY CHANGE: filter the bias-corrected signal

figure;
plot(timeVectorSec, EMG_raw, 'b', 'DisplayName', 'Raw EMG'); hold on;
plot(timeVectorSec, emg_filtered, 'r', 'LineWidth', 1.2, 'DisplayName', 'Filtered EMG (20–400 Hz)');
xlabel('Time (s)');
ylabel('EMG amplitude (µV)');
title('EMG: Raw vs Band-pass Filtered');
legend;
grid on;
%% Step 3: RectificationRectification converts the bipolar EMG signal into a unipolar signal.
% This is done by taking the absolute value of the filtered EMG.
% It preserves the timing of the activity but makes all values positive,
% which is required for calculating the EMG envelope or RMS later.
emg_rectified = abs(emg_filtered);

% Plot raw vs rectified
figure;
plot(timeVectorSec, emg_filtered, 'b'); hold on;
plot(timeVectorSec, emg_rectified, 'r');
xlabel('Time (s)');
ylabel('Amplitude');
title('EMG: Filtered vs Rectified');
legend('Filtered EMG','Rectified EMG');
grid on;

%% Step 3: Rectification
% Make all EMG values positive (full-wave rectification)
emg_rectified = abs(emg_filtered);

%% Step 4: Envelope
% Smooth the rectified EMG using a low-pass filter (5–10 Hz)
[b_env, a_env] = butter(4, 10/(fs/2), 'low');  
emg_envelope = filtfilt(b_env, a_env, emg_rectified);
%% Plot EMG envelope to visually check baseline region
figure;
plot(timeVectorSec, emg_envelope, 'b', 'LineWidth', 1.2); hold on;

% Draw a vertical line at first force contact
if exist('contactOnTimes','var') && ~isempty(contactOnTimes)
    xline(contactOnTimes(1), 'r--', 'First Fz contact');
elseif exist('validContacts','var') && ~isempty(validContacts)
    xline(validContacts(1)/fs, 'r--', 'First Fz contact');
end

xlabel('Time (s)');
ylabel('EMG Envelope (a.u.)');
title('EMG Envelope with first force contact');
grid on;
%% Step 5: Select baseline region (quiet phase)
% Define baseline window in seconds
baselineStartSec = 0.1;   % start of quiet phase
baselineEndSec   = 1.1;   % end of quiet phase

% Convert to indices
baselineStartIdx = round(baselineStartSec * fs);
baselineEndIdx   = round(baselineEndSec * fs);

% Extract baseline segment
baselineSegment = emg_envelope(baselineStartIdx:baselineEndIdx);

% Compute mean and SD of baseline
baselineMean = mean(baselineSegment);
baselineSD   = std(baselineSegment);

%% Step 6: Threshold and onset detection
% Threshold = mean + 3*SD
onsetThreshold = baselineMean + 3 * baselineSD;

% Find first index where envelope crosses threshold
onsetIndex = find(emg_envelope > onsetThreshold, 1, 'first');
onsetTime  = onsetIndex / fs;

% Plot to visualize
figure;
plot(timeVectorSec, emg_envelope, 'b', 'LineWidth', 1.2); hold on;
yline(onsetThreshold, 'r--', 'Threshold');
xline(onsetTime, 'g--', sprintf('Onset = %.3f s', onsetTime));
xline(baselineStartSec, 'k--', 'Baseline Start');
xline(baselineEndSec, 'k--', 'Baseline End');
xlabel('Time (s)');
ylabel('EMG Envelope (a.u.)');
title('EMG Envelope with Baseline and Onset Detection');
grid on;

% Print results
fprintf('Baseline Mean = %.5f, SD = %.5f\n', baselineMean, baselineSD);
fprintf('Onset detected at index %d (time = %.3f s)\n', onsetIndex, onsetTime);
%% Step 5: Baseline region (quiet phase)
baselineStartSec = 0.1;   % sec (adjust if needed)
baselineEndSec   = 1.1;   % sec (adjust if needed)
baselineStartIdx = round(baselineStartSec * fs);
baselineEndIdx   = round(baselineEndSec * fs);
baselineSegment = emg_envelope(baselineStartIdx:baselineEndIdx);

baselineMean = mean(baselineSegment);
baselineSD   = std(baselineSegment);

%% Step 6: Thresholds
onsetThreshold  = baselineMean + 3 * baselineSD;   % higher threshold for onset
offsetThreshold = baselineMean + 1.5 * baselineSD; % lower threshold for offset

%% Step 7: Stability condition (25–50 ms rule)
minStableSamples = round(0.18 * fs);  % 25 ms, can change to 0.05*fs for 50 ms

%% Onset detection (first time envelope stays above onsetThreshold for >= 25 ms)
onsetIndex = NaN;
for i = 1:(length(emg_envelope) - minStableSamples)
    if all(emg_envelope(i:i+minStableSamples-1) > onsetThreshold)
        onsetIndex = i;
        break;
    end
end
if ~isnan(onsetIndex)
    onsetTime = onsetIndex / fs;
else
    onsetTime = NaN;
end

%% Offset detection (first time envelope stays below offsetThreshold for >= 25 ms, after Fz contact off)
offsetIndex = NaN;
if ~isnan(onsetIndex) && ~isempty(contactOffTimes)
    startIdx = round(contactOffTimes(1) * fs);  % start search from Fz contact off
    for i = startIdx:(length(emg_envelope) - minStableSamples)
        if all(emg_envelope(i:i+minStableSamples-1) < offsetThreshold)
            offsetIndex = i;
            break;
        end
    end
end
if ~isnan(offsetIndex)
    offsetTime = offsetIndex / fs;
else
    offsetTime = NaN;
end


%% Plot EMG envelope with thresholds, onset, and offset
figure;
plot(timeVectorSec, emg_envelope, 'b', 'LineWidth', 1.2); hold on;

% Plot thresholds
yline(onsetThreshold,  'r--', 'Onset Th');
yline(offsetThreshold, 'm--', 'Offset Th');

% Plot onset and offset
if ~isnan(onsetIndex)
    xline(onsetTime, 'g--', sprintf('Onset = %.3f s', onsetTime));
end
if ~isnan(offsetIndex)
    xline(offsetTime, 'k--', sprintf('Offset = %.3f s', offsetTime));
end

% Add Fz contact on/off lines for reference
if exist('contactOnTimes','var') && ~isempty(contactOnTimes)
    xline(contactOnTimes(1), 'c--', 'Fz Contact On');
end
if exist('contactOffTimes','var') && ~isempty(contactOffTimes)
    xline(contactOffTimes(1), 'm--', 'Fz Contact Off');
end

xlabel('Time (s)');
ylabel('EMG Envelope (a.u.)');
title('EMG Onset/Offset with Thresholds and Fz Contact Events');
grid on;

%% Print results
fprintf('Baseline Mean = %.5f, SD = %.5f\n', baselineMean, baselineSD);
fprintf('Onset Th = %.5f, Offset Th = %.5f\n', onsetThreshold, offsetThreshold);
if ~isnan(onsetIndex)
    fprintf('Onset:  Index = %d, Time = %.3f s\n', onsetIndex, onsetTime);
else
    fprintf('Onset not found (check threshold)\n');
end
if ~isnan(offsetIndex)
    fprintf('Offset: Index = %d, Time = %.3f s\n', offsetIndex, offsetTime);
else
    fprintf('Offset not found (check threshold)\n');
end
%% Feedforward (pre-activation) and Feedback (post-activation) analysis =====

% Assumes:
% - onsetTime (s) and offsetTime (s) are already computed
% - contactOnTimes(1) and contactOffTimes(1) are from force plate detection

if ~isempty(contactOnTimes) && ~isempty(contactOffTimes) && ~isnan(onsetTime) && ~isnan(offsetTime)
    
    % Feedforward (pre-activation vs reactive)
    feedforwardLatency = onsetTime - contactOnTimes(1);
    if feedforwardLatency < 0
        fprintf('Feedforward (Pre-activation): %.3f s before contact\n', abs(feedforwardLatency));
    else
        fprintf('Reactive Onset: %.3f s after contact\n', feedforwardLatency);
    end
    
    % Feedback (offset relative to force plate end)
    feedbackLatency = offsetTime - contactOffTimes(1);
    if feedbackLatency < 0
        fprintf('Muscle deactivated %.3f s before end of contact\n', abs(feedbackLatency));
    else
        fprintf('Post-activation: %.3f s after contact ended\n', feedbackLatency);
    end
    
else
    warning('Onset/offset or contact times are missing. Cannot compute feedforward/feedback.');
end
