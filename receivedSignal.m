function signal = receivedSignal(paths)
    % goes through all of the individual paths in the input and adds the
    % waveforms together if they're detected to get the received signal

    signal = zeros(size(paths{1}.burst));

    for ii = 1:length(paths)
        if paths{ii}.detected
            signal = signal + paths{ii}.burst;
        end
    end
end