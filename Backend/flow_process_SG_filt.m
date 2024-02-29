function [dts, pkpk] = flow_process_SG_filt(upvolts, downvolts, time, N_interp, up_is, down_is)

%     [dts, corr_x, corr] = flow_process_SG_filt(upvolts, downvolts, time, N_interp, up_is, down_is)
%     Function to process flow data. 
%     This version does savitzky golay filtering then cubic spline
%     interpolation, which preserves the shape and phase of the pulse better 
%     than frequency domain methods.
%     
%     It takes upvolts, downvolts, time,an interpolation factor (reccomend
%     100), and up_is and down_is, which can be calculated using
%     auto_start_stop.m. It returns a list of times which are the v-path time
%     differences due to the flow.
    

    %disp("Processing data");
    
%     spect = fftshift(fft(upvolts));
%     nyquist = 1/(2*(time(2)-time(1)));
%     freq = linspace(-nyquist, nyquist, length(spect));

%     start_i = 1869;
%     stop_i = 2068;
%     hanning_part = hanning(2068-1869);
%     freq_filt = zeros(size(freq));
%     freq_filt(start_i:stop_i-1) = hanning_part;
%     spect = fftshift(fft(upvolts));
%     spect = spect.*freq_filt';
%     upvolts = real(ifft(ifftshift(spect)));
%     spect = fftshift(fft(downvolts));
%     spect = spect.*freq_filt';
%     downvolts = real(ifft(ifftshift(spect)));
    
    dts = zeros(1,length(up_is));
    %start looping through arrivals
    for arr_i = 1:length(up_is)       

        %pick out arrival
        i1 = up_is(arr_i);
        i2 = down_is(arr_i);
        %i1 = ceil((i1+i2)/2); %second half only
        
        arr1 = upvolts(i1:i2);
        arr2 = downvolts(i1:i2);
        t_crop = time(i1:i2);
        
        %savitzky golay filter with window length 15, 3rd order
        arr1_filt = sgolayfilt(arr1, 3, 15);
        arr2_filt = sgolayfilt(arr2, 3, 15);
        
        %cubic spline interpolate
        time_int = linspace(t_crop(1), t_crop(end), length(t_crop)*N_interp);
        arr1_int = spline(t_crop, arr1_filt, time_int);
        arr2_int = spline(t_crop, arr2_filt, time_int);

        % peak to peak of interpolated signal
        pkpk = max(arr1_int) - min(arr1_int);

        %cross correlate
        [corr, corr_i] = xcorr(arr1_int, arr2_int);
        corr_x = corr_i*(time_int(2)-time_int(1));
        [~, max_i] = max(corr);
        dt =  corr_x(max_i);
        
        %add to dts
        dts(arr_i) = dt; %subtract time difference due to electronics box
       
    end %for over arrivals

end