function signal = receivedSignal(paths)
    % goes through all of the individual paths in the input and adds the
    % waveforms together if they're detected to get the received signal

    signal = zeros(size(paths{1}.burst));

    for ii = 1:size(paths, 1)
        for jj = 1:size(paths, 2)
            if paths{ii,jj}.detected
                signal = signal + paths{ii,jj}.burst;
            end
        end
    end
end