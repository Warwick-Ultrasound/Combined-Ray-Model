function [starts, stops, envelope] = arrival_detect(volts, N_arrivals)
    %normalise
    volts = volts/max(volts);
    
    envelope = abs(hilbert(volts));

    win_length = 4*floor(0.01*length(volts)/2)+1;
    envelope = sgolayfilt(envelope, 2, win_length);
    
    [peaks, locs] = findpeaks(envelope, 'MinPeakDistance', 0.1*length(volts));
    
    %find N_arrivals highest peaks and use those as a starting point
    [~, sort_ind] = sort(peaks, 'descend');
    locs = locs(sort_ind);
    locs = locs(1:N_arrivals);

    lowvals = find(envelope<0.025);

    troughs = lowvals; %only uses <5%
    %troughs = sort(troughs);
    
    %get starts and stops from troughs to left and right of centre values
    starts = zeros(1, N_arrivals);
    stops = zeros(size(starts));
    for ii = 1:N_arrivals
       centre_i = locs(ii);
       [starts(ii), stops(ii)] = find_start_stop(centre_i, troughs);
    end
 
    starts = sort(starts);
    stops = sort(stops);
end
function [start, stop] = find_start_stop(centre_i, troughs)
    % takes index centre_i and an array of indices, troughs. Finds the
    % index in troughs which is closest to, but smaller than centre_i
    x = troughs - centre_i; %only consider -ve elements, want closest to zero
    for ii = 1:length(troughs)
        if x(ii)>0
            start = troughs(ii-1);
            stop = troughs(ii);
            break;
        end
    end
end